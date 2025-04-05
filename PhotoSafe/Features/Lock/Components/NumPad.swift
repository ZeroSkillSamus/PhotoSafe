//
//  SwiftUIView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct NumPad: View {
    let numbers: [String] = ["1","2","3","4","5","6","7","8","9"]
    @Binding var passcode: String
    @Binding var is_secure: Bool
    
    var body: some View {
        LazyVGrid(columns: [GridItem(),GridItem(),GridItem()]) {
            ForEach(self.numbers,id:\.self) { num in
                NumButton(num: num, passcode: self.$passcode)
            }
            
            // Reveal Hidden Passcode
            Button {
                self.is_secure.toggle()
            } label: {
                Image(systemName: "eye")
                    .font(.title2)
                    .foregroundColor(.blue)
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
        }
    }
    
    struct NumButton: View {
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
}

