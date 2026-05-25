//
//  SwiftUIView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct NumPad: View {
    @EnvironmentObject var authViewmodel: AuthStorageViewModel
    
    @Binding var passcode: String
    @Binding var isSecure: Bool
    
    var body: some View {
        LazyVGrid(columns: [GridItem(),GridItem(),GridItem()]) {
            ForEach(1...9,id:\.self) { num in
                NumButton(num: String(num), passcode: self.$passcode)
            }
            
            if !authViewmodel.isPinSet{
                Button {
                    authViewmodel.createPin(pin: self.passcode)
                } label: {
                    Text("Set Pin")
                }
                .opacity(self.passcode.count == 6 ? 1 : 0)
            } else {
                Button {
                    print("soon")
                } label: {
                    Image(systemName: "faceid")
                        .font(.title2)
                        .foregroundStyle(Color.c1_accent)
                }
            }
            
            NumButton(num: "0", passcode: self.$passcode)
            
            // Delete Button
            Button {
                let _ = self.passcode.popLast()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .opacity(self.passcode.isEmpty ? 0 : 1)
            //.animation(.easeInOut, value: self.passcode.isEmpty)
        }
        .animation(.easeInOut, value: self.passcode.isEmpty)
    }
    
    struct NumButton: View {
        let num: String
        @Binding var passcode: String
        
        var body: some View {
            Button {
                self.passcode.append(num)
            } label: {
                Text(num)
                    .font(.system(size: 20,weight: .semibold,design: .rounded))
                    .frame(width: 70, height: 70) // Fixed size
                    .background(Color.c1_secondary)
                    .foregroundColor(Color.c1_text)
                    .clipShape(Circle())
            }
            .padding(.horizontal)
        }
    }
}

