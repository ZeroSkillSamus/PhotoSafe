import Foundation
import CryptoKit

protocol AuthStorageServiceProtocol {
    func savePin(_ pin: String) throws
    func verifyPin(_ pin: String) throws -> Bool
    func deletePin() throws
    var isPinSet: Bool { get }
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
      try self.keychainService.save(hash(pin), forKey: self.pinKey)
      userDefaults.set(true, forKey: pinSetKey)
    }

    func verifyPin(_ pin: String) throws -> Bool {
      guard let stored = try self.keychainService.get(self.pinKey) else {
          return false
      }
      return hash(pin) == stored
    }

    func deletePin() throws {
      try self.keychainService.delete(self.pinKey)
      userDefaults.set(false, forKey: pinSetKey)
    }

    private func hash(_ pin: String) -> String {
      let data = Data(pin.utf8)
      let digest = SHA256.hash(data: data)
      return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

struct PasswordHasher {
    static func hash(_ password: String) -> (Data?, Data?) {
        let salt = generateSalt()
        let hash = SHA256.hash(data: salt + Data(password.utf8))
        return (salt, Data(hash))
    }
    
    static func verify(_ enteredPassword: String, for albumEntity: AlbumEntity) -> Bool {
        // Create hash from entered password
        guard let storedSalt = albumEntity.passwordSalt, let storedHash = albumEntity.passwordHash else {
            return false
        }
        let newPasswordHash = SHA256.hash(data: storedSalt + Data(enteredPassword.utf8))
        return Data(newPasswordHash) == storedHash
    }
    
    private static func generateSalt(length: Int = 16) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)

        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            bytes.count,
            &bytes
        )

        guard status == errSecSuccess else {
            fatalError("Failed to generate secure random salt")
        }

        return Data(bytes)
    }
    
}
