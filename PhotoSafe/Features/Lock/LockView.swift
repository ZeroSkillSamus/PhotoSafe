//
//  LockScreen.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/26/25.
//

import SwiftUI

struct LockView: View {
    @State private var numberInput: String = ""
    @State private var is_secure: Bool = true
    
    // When is_secure is 'true' create a string of '*'
    // To match the number of characters in 'numberInput'
    func secure_handler() -> String {
        return String(repeating: "*", count: self.numberInput.count)
    }
    
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .frame(width: 250, height: 250)
                
            Spacer()
            
            VStack(spacing: 15) {
                Text("Enter Password")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textContentType(.password)
                
                VStack(spacing: 40) {
                    Text(self.is_secure ? secure_handler() : self.numberInput)
                        .font(.title)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, maxHeight: 45)
                        .background(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Create a Custom NumPad
                    NumPad(
                        passcode: self.$numberInput,
                        is_secure: self.$is_secure
                    )
                }
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .bottom)
            .padding(.bottom,50)
            
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
    }
}

#Preview {
    LockView().preferredColorScheme(.dark)
}
