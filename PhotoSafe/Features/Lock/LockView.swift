//
//  LockScreen.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/26/25.
//

import SwiftUI

struct LockView: View {
    @EnvironmentObject var authViewModel: AuthStorageViewModel
    
    @State private var numberInput: String = ""
    @State private var isSecure: Bool = true
    @State private var passwordAttempt: Int = 0
       
    // When is_secure is 'true' create a string of '*'
    // To match the number of characters in 'numberInput'
    func secure_handler() -> String {
        return String(repeating: "*", count: self.numberInput.count)
    }
    
    var defaultText: String {
        if self.numberInput.isEmpty {
            return "Waiting For Input..."
        }
        
        return self.isSecure ? secure_handler() : self.numberInput
    }
    
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "lock.shield.fill")
                    .resizable()
                    .font(.largeTitle)
                
                Text("Photosafe")
                    .font(.system(size: 25,weight: .semibold,design: .rounded))
            }
            .frame(width: 150, height: 200,alignment: .top)
            .padding(.bottom)
            .foregroundStyle(Color.c1_primary)
            
            Spacer()
            
            VStack(spacing: 9) {
                if !self.authViewModel.isPinSet {
                    Text("Create a secure pin")
                        .font(
                            .system(
                                size: 25,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color.c1_text)
                    
                    Text("PIN must be 6 characters long")
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .opacity(0.75)
                        .foregroundStyle(Color.c1_text)
                } else {
                    Text("Need Authorization")
                        .font(
                            .system(
                                size: 25,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color.c1_text)
                    
                    Text("Enter your PIN to unlock")
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .opacity(0.75)
                        .foregroundStyle(Color.c1_text)
                }
                
                //Spacer()
            }
            Spacer()
            // Text Input
            Text(self.defaultText)
                .opacity(0.75)
                .foregroundStyle(Color.c1_text)
                .font(
                    .system(
                        size: 18,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: 45)
                .background(passwordAttempt > 0 ? Color.red : Color.c1_secondary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)
                
            
            Spacer()
            
            // Create a Custom NumPad
            NumPad(
                passcode: self.$numberInput,
                isSecure: self.$isSecure
            )
            Spacer()
        }
        .padding(.horizontal)
        .background(Color.c1_background)
        .onChange(of: self.numberInput) { _, new in
            if !self.authViewModel.isPinSet {
                if new.count > 6 {
                    self.numberInput.removeLast()
                }
            } else if new.count == 6 {
                if !authViewModel.verifyPin(for: new) {
                    numberInput = ""
                    passwordAttempt = passwordAttempt + 1
                } else {
                    passwordAttempt = 0
                }
            }
        }
        .orientationLock(.portrait)
        .onAppear {
            self.numberInput = ""
        }
    }
}
