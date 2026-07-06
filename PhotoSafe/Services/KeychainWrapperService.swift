//
//  KeychainWrapperService.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 5/27/26.
//

//import SwiftKeychainWrapper
import KeychainAccess
import Foundation

protocol KeychainServiceProtocol {
    func save(_ value: String, forKey key: String) throws
    func save(_ value: Data, forKey key: String) throws
    func getData(_ key: String) throws -> Data?
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
    
    func getData(_ key: String) throws -> Data? {
        try keychain.getData(key)
    }
    
    func save(_ value: String, forKey key: String) throws {
        try keychain.set(value, key: key)
    }
    
    func save(_ value: Data, forKey key: String) throws {
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
