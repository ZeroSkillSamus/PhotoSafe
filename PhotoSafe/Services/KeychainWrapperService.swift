//
//  KeychainWrapperService.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 5/27/26.
//

//import SwiftKeychainWrapper
import KeychainAccess

protocol KeychainServiceProtocol {
    func save(_ value: String, forKey key: String) throws
    func get(_ key: String) throws -> String?
    func delete(_ key: String) throws
    func removeAll() throws
}

final class KeyChainWrapperService: KeychainServiceProtocol {
    static let shared = KeyChainWrapperService()
    
    private let keychain: Keychain
    
    private init() {
        self.keychain = Keychain(service: "com.photosafe.auth")
            .accessibility(.whenUnlocked)
            .synchronizable(false)
    }
    
    func save(_ value: String, forKey key: String) throws {
        try keychain.set(value, key: key)
    }

    func get(_ key: String) throws -> String? {
        try keychain.get(key)
    }
    
    func delete(_ key: String) throws {
        try keychain.remove(key)
    }
    
    func removeAll() throws {
        try keychain.removeAll()
    }
}
