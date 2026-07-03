import Foundation
import CommonCrypto

protocol AuthStorageServiceProtocol {
    func savePin(_ pin: String) throws
    func verifyPin(_ pin: String) throws -> Bool
    func deletePin() throws
    var isPinSet: Bool { get }
}

enum HashError: Error {
    case hashOrSaltMissing
    case savedPinNotFound
    case failedToGenerateSalt
    case failedToGenerateHashPassword
}

final class AuthStorageService: AuthStorageServiceProtocol {
    static let shared = AuthStorageService()

    private let keychainService: KeychainServiceProtocol
    private let userDefaults: UserDefaults
    private let pinKey = "pinKey"
    private let pinSetKey = "isPinSet"

    init(
      keychainService: KeychainServiceProtocol = KeyChainWrapperService.shared,
      userDefaults: UserDefaults = .standard
    ) {
        self.keychainService = keychainService
        self.userDefaults = userDefaults
    }

    var isPinSet: Bool {
        userDefaults.bool(forKey: pinSetKey)
    }

    func savePin(_ pin: String) throws {
        let hashedPin = try PasswordHasher.hashForPin(pin)
        try self.keychainService.save(hashedPin, forKey: self.pinKey)
        userDefaults.set(true, forKey: pinSetKey)
    }

    func verifyPin(_ pin: String) throws -> Bool {
        guard let stored = try self.keychainService.get(self.pinKey) else {
            throw HashError.savedPinNotFound
        }
        return try PasswordHasher.verifyPin(storedHash: stored, enteredPin: pin)
    }

    func deletePin() throws {
      try self.keychainService.delete(self.pinKey)
      userDefaults.set(false, forKey: pinSetKey)
    }
}

struct PasswordHasher {
    static let iterations = 210_000
    static let algorithm = "pbkdf2-sha256"
    
    // Hashing handler for pin
    static func hashForPin(_ pin: String) throws -> String {
        let (salt, hashData) = try PasswordHasher.hash(pin)
        guard let salt, let hashData else { throw  HashError.hashOrSaltMissing }
        
        let storedPin = "\(algorithm)$\(iterations)$\(salt.base64EncodedString())$\(hashData.base64EncodedString())"
        return storedPin
    }
    
    // Hashing handler for album passwords
    static func hash(_ password: String) throws -> (Data?, Data?)  {
        let salt = try generateSalt()
        let hash = try pbkdf2(password: password, salt: salt)
        return (salt, Data(hash))
    }
    
    static func verify(_ enteredPassword: String, for albumEntity: AlbumEntity) throws -> Bool {
        // Create hash from entered password
        guard let storedSalt = albumEntity.passwordSalt, let storedHash = albumEntity.passwordHash else {
            return false
        }
        let newPasswordHash = try pbkdf2(password: enteredPassword, salt: storedSalt)
        return timingSafeCompare(newPasswordHash, storedHash)
    }
    
    static func verifyPin(storedHash: String, enteredPin: String) throws -> Bool {
        let parts = storedHash.components(separatedBy: "$")
        
        guard parts.count == 4,
              parts[0] == PasswordHasher.algorithm,
              let iterations = Int(parts[1]),
              let salt = Data(base64Encoded: parts[2]),
              let storedHash = Data(base64Encoded: parts[3]) else
        {
            return false
        }
        
        let attemptedHash = try PasswordHasher.pbkdf2(
            password: enteredPin,
            salt: salt,
            iterations: iterations,
            keyByteCount: storedHash.count
        )
        
        return timingSafeCompare(attemptedHash, storedHash)
    }
    
    private static func generateSalt(length: Int = 16) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: length)

        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            bytes.count,
            &bytes
        )

        guard status == errSecSuccess else {
            throw HashError.failedToGenerateSalt
        }

        return Data(bytes)
    }
    
    private static func pbkdf2(
        password: String,
        salt: Data,
        iterations: Int = iterations,
        keyByteCount: Int = 32
    ) throws -> Data {
        var derivedKey = Data(repeating: 0, count: keyByteCount)

        let status = password.withCString { passwordPointer in
            salt.withUnsafeBytes { saltBytes in
                derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordPointer,
                        password.utf8.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyByteCount
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw HashError.failedToGenerateHashPassword
        }

        return derivedKey
    }
    
    // Ensure we dont leak where the mismatch happened
    private static func timingSafeCompare(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }

        var difference: UInt8 = 0

        for index in lhs.indices {
            difference |= lhs[index] ^ rhs[index]
        }

        return difference == 0
    }
}
