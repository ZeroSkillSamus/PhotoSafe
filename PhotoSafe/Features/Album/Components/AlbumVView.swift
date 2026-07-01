//
//  AlbumVView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/6/25.
//

import SwiftUI

struct AlbumVDisplay: View {
    @EnvironmentObject private var album_VM: AlbumViewModel
    @EnvironmentObject private var favoritesViewModel: FavoriteViewModel
    
    var album: AlbumEntity
    //@State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    @State private var showPasswordAlert = false
    @State private var password: String = ""
    
    @State private var showDeleteAlert = false
    
    @Binding var toast: ToastItem?
    @Binding var isEditModeEnabled: Bool
    var openAction: () -> Void
    var editAction: () -> Void
    
    private let actionRevealWidth: CGFloat = 176
    private let actionButtonSize: CGFloat = 80
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 8) {
                Button(action: self.editAction) {
                    VStack(spacing: 5) {
                        Image(systemName: "pencil")
                            .font(.title3)
                        
                        Text("Edit")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .frame(width: self.actionButtonSize, height: self.actionButtonSize)
                    .foregroundStyle(Color.c1_text)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.c1_accent.opacity(0.7)))
                }
                .buttonStyle(.plain)
                
                Button {
                    // show alert
                    if album.is_locked {
                        self.showPasswordAlert = true
                    } else {
                        self.showDeleteAlert = true
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                        
                        Text("Delete")
                            .font(.system(size: 15,weight: .medium,design: .rounded))
                    }
                    .frame(width: self.actionButtonSize, height: self.actionButtonSize)
                    .foregroundStyle(Color.c1_text)
                    .background(RoundedRectangle(cornerRadius: 15).fill(.red).opacity(0.7))
                }
                .buttonStyle(.plain)
                .alert("Enter Password", isPresented: $showPasswordAlert) {
                    TextField("Password", text: $password)

                    Button("Continue") {
                        if password == album.password {
                            password = ""
                            showDeleteAlert = true
                        } else {
                            password = ""
                            toast = ToastItem(message: "Incorrect password", status: .failure)
                        }
                    }

                    Button("Cancel", role: .cancel) {
                        password = ""
                    }
                } message: {
                    Text("Enter the album password to delete \(album.name).")
                }
                .alert("Delete \(album.name) album?", isPresented: self.$showDeleteAlert) {
                    Button(role: .destructive) {
                        do {
                            try self.album_VM.delete(album: album)
                            self.toast = ToastItem(message: "Successfully Deleted", status: .success)
                            self.favoritesViewModel.setFavorites()
                            if album_VM.albums.isEmpty {
                                withAnimation {
                                    self.isEditModeEnabled.toggle()
                                }
                            }
                        } catch {
                            self.toast = ToastItem(message: "Failed to delete \(album.name)", status: .failure)
                        }
                    } label: {
                        Text("Delete")
                    }

                    Button(role: .cancel) {
                    } label: {
                        Text("Cancel")
                    }
                } message: {
                    Text("This will permanently delete the album and its saved media.")
                }
            }
            .frame(width: self.actionRevealWidth, alignment: .trailing)
            .opacity(self.isEditModeEnabled ? 1 : 0)
            
            Button(action: self.openAction) {
                HStack {
                    AlbumImageDisplay(album: album)
                        .frame(width: 80, height:85)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack {
                        Text(album.name)
                            .foregroundStyle(Color.c1_text)
                            .font(.system(size: 20,weight: .semibold,design: .rounded))
                            .frame(maxWidth: .infinity,alignment: .leading)
                        Text("^[\(album.mediaCount) item](inflect: true)")
                            .foregroundStyle(Color.c1_text)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .opacity(0.75)
                            .frame(maxWidth: .infinity,alignment: .leading)
                    }
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .padding(.leading,15)
                    
                    Spacer()
                    
                    if album.is_locked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(Color.c1_primary)
                            .padding(.trailing,20)
                    }
                }
                .frame(maxWidth:.infinity)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.c1_secondary).opacity(0.7))
            }
            .buttonStyle(.plain)
            .offset(x: self.isEditModeEnabled ? -self.actionRevealWidth : 0)
        }
    }
}
