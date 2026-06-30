//
//  AuthStorageViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 5/27/26.
//

import Foundation
import LocalAuthentication

@MainActor
class AuthStorageViewModel: ObservableObject {
    private let authService: AuthStorageService

    @Published private(set) var isPinSet: Bool
    @Published private(set) var isUnlocked: Bool = false
    @Published var showPrivacyOverlay: Bool = true

    enum ChangePinResult {
        case success
        case currentPinIncorrect
        case invalidNewPin
        case pinMismatch
        case failed
    }
    
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
        } catch {}
    }
    
    func verifyPin(for pin: String) -> Bool {
        self.isUnlocked = isPinVerified(for: pin)
        return self.isUnlocked
    }

    func isPinVerified(for pin: String) -> Bool {
        do {
            return try self.authService.verifyPin(pin)
        } catch {
            return false
        }
    }
    
    func changePin(currentPin: String, newPin: String, confirmPin: String) -> ChangePinResult {
        guard currentPin.count == 6, newPin.count == 6, confirmPin.count == 6 else {
            return .invalidNewPin
        }

        guard newPin == confirmPin else {
            return .pinMismatch
        }

        do {
            guard try self.authService.verifyPin(currentPin) else {
                return .currentPinIncorrect
            }

            try self.authService.savePin(newPin)
            self.isPinSet = true
            self.isUnlocked = true
            return .success
        } catch {
            return .failed
        }
    }
    
    func lockApp() {
        self.isUnlocked = false
    }
    
/// Initiates Face ID authentication flow
    func faceIDAuthentification() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            self.isUnlocked = false
            return true
        }
        
        let reason = "FaceID Needed To Login"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                self.isUnlocked = true
                return false
            } else {
                self.isUnlocked = false
                return true
            }
        } catch {
            self.isUnlocked = false
            return false
        }
    }
}
