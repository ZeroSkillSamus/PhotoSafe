//
//  MediaEncryptionService.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 7/5/26.
//

import Foundation
import CryptoKit

protocol MediaEncryptionServiceProtocol {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ data: Data) throws -> Data
}

enum MediaEncryptionError: Error {
    case failedToCreateSealedBox
    case dirCreationFailed
}

class MediaEncryptionService: MediaEncryptionServiceProtocol {
    static let shared = MediaEncryptionService()
    
    private let keychainService: KeychainServiceProtocol
    private let vaultKeyName = "mediaVaultKey"
    
    private var cachedVaultKey: SymmetricKey?
    
    init(keychainService: KeychainServiceProtocol = KeyChainWrapperService.shared) {
        self.keychainService = keychainService
    }
    
    private func vaultKey() throws -> SymmetricKey {
        if let cachedVaultKey {
            return cachedVaultKey
        }

        let key = try loadOrCreateVaultKey()
        self.cachedVaultKey = key
        return key
    }
    
    func encrypt(_ data: Data) throws -> Data {
        let key = try vaultKey()
        let sealedBox = try AES.GCM.seal(data, using: key)

        guard let combined = sealedBox.combined else {
            throw MediaEncryptionError.failedToCreateSealedBox
        }

        return combined
    }
    
    func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try vaultKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func loadOrCreateVaultKey() throws -> SymmetricKey {
        if let savedKeyData = try keychainService.getData(vaultKeyName) {
            return SymmetricKey(data: savedKeyData)
        }

        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        try keychainService.save(keyData, forKey: vaultKeyName)

        return newKey
    }
}
