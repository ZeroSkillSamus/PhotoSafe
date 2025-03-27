//
//  LockScreen.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/26/25.
//

import SwiftUI

struct LockScreen: View {
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
                    CustomNumPad(
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

struct CustomNumPad: View {
    let numbers: [String] = ["1","2","3","4","5","6","7","8","9"]
    @Binding var passcode: String
    @Binding var is_secure: Bool
    
    var body: some View {
        LazyVGrid(columns: [GridItem(),GridItem(),GridItem()]) {
            ForEach(self.numbers,id:\.self) { num in
                CustomButton(num: num, passcode: self.$passcode)
            }
            
            Button {
                self.is_secure.toggle()
            } label: {
                Image(systemName: "eye")
                    .font(.title)
            }
            
            CustomButton(num: "0", passcode: self.$passcode)
            // Delete Button
            Button {
                let _ = self.passcode.popLast()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title)
            }
        }
    }
}

struct CustomButton: View {
    let num: String
    @Binding var passcode: String
    
    var body: some View {
        Button {
            self.passcode.append(num)
        } label: {
            Text(num)
                .padding()
                .font(.system(size: 20,weight: .semibold,design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.secondary)
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    LockScreen().preferredColorScheme(.dark)
}
