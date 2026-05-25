//
//  AuthStorageViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 5/27/26.
//

import Foundation
 
@MainActor
class AuthStorageViewModel: ObservableObject {
    private let authService: AuthStorageService

    @Published private(set) var isPinSet: Bool
    @Published private(set) var isUnlocked: Bool = false
    
    init(authService: AuthStorageService = AuthStorageService.shared) {
        self.authService = authService
        self.isPinSet = authService.isPinSet
    }

    func createPin(pin: String) {
        if pin.count != 6 { return }
        do {
            try self.authService.savePin(pin)
            self.isPinSet = true
            self.isUnlocked = true
        } catch {
            print(error)
        }
    }
    
    func verifyPin(for pin: String) -> Bool {
        do {
            self.isUnlocked = try self.authService.verifyPin(pin)
            return isUnlocked
        } catch (let error) {
            print(error)
            self.isUnlocked = false
            return false
        }
    }
    
    func lockApp() {
        self.isUnlocked = false
    }
}
