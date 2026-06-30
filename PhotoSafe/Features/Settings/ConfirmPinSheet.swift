//
//  ConfirmPinSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/29/26.
//

import SwiftUI

struct ConfirmPinSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject private var albumViewModel: AlbumViewModel
    @EnvironmentObject private var favoritesViewModel: FavoriteViewModel
    @EnvironmentObject private var authViewModel: AuthStorageViewModel
    
    @State private var passcode: String = ""
    @State private var isSecure: Bool = true
  
    @Binding var toast: ToastItem?
    
    var body: some View {
        ZStack {
            Color.c1_secondary.opacity(0.8).ignoresSafeArea()
            
            VStack {
                Text("Confirm PIN")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .padding(.bottom, 5)
                    .foregroundStyle(Color.c1_text)
                
                
                Text("Enter your PIN to permanently delete all albums and media from PhotoSafe.")
                    .font(.system(size: 17, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.c1_text)
                    .opacity(0.75)
                
                HStack(spacing: 15) {
                    ForEach((0..<6), id: \.self) { index in
                        // 2              0
                        if passcode.count > index {
                            Circle()
                                .fill(Color.c1_primary)
                                .frame(width: 25,height: 25)
                        } else {
                            Circle()
                                .stroke()
                                .foregroundStyle(Color.c1_text)
                                .frame(width: 24,height: 24)
                                //.padding(7)
                        }
                        
                    }
                }
                .padding(.vertical)
                
                NumPad(passcode: self.$passcode, isSecure: self.$isSecure,screenType: .DeleteAll)
                
                Button {
                    // Verify Pin
                    if !authViewModel.isPinVerified(for: self.passcode) {
                        self.toast = ToastItem(message: "Wrong PIN", status: .failure)
                        self.passcode = ""
                    } else {
                        do {
                            try self.albumViewModel.deleteAll()
                            self.favoritesViewModel.setFavorites()  // Clear favoritesn
                            
                            self.toast = ToastItem(message: "Successfully Deleted All Media", status: .success)
                            self.dismiss()
                        } catch {
                            self.toast = ToastItem(message: "Could not delete all media", status: .failure)
                            self.passcode = ""
                        }
                    }
                    
                } label: {
                    Text("Delete All")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding(5)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.red)
                .buttonBorderShape(.roundedRectangle(radius: 10))
                .padding(.top,10)
                .opacity(self.passcode.count == 6 ? 1 : 0)
                .disabled(passcode.count != 6)
            }
            .displayToast(self.$toast)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal,5)
            .padding(.top,30)
            .onChange(of: self.passcode) { oldValue, newValue in
                if newValue.count > 6 { self.passcode.removeLast() }
            }
            
        }
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.visible)
    }
}
