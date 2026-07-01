//
//  AlbumEditView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/9/25.
//

import SwiftUI
import PhotosUI
import AudioToolbox

struct AlbumEditView: View {
    @StateObject private var editSheetViewModel: EditSheetViewModel = EditSheetViewModel()
    
    @EnvironmentObject private var albumViewModel: AlbumViewModel
    @EnvironmentObject private var favoritesViewModel: FavoriteViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var album: AlbumEntity
    @Binding var editModeActive: Bool
    
    @State private var avatar: PhotosPickerItem?
    @State private var showingPhotosPicker: Bool = false
    
    @State private var toast: ToastItem?
   
    @State private var showDeleteAlert: Bool = false
    var body: some View {
        VStack {
            // Header
            HStack {
                Button {
                    self.dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(Color.c1_text)
                        .font(.system(size: 19,weight: .semibold, design: .rounded))
                        .opacity(0.75)
                }
                Spacer()
                
                Button {
                    let trimmed = self.editSheetViewModel.album_name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        self.toast = ToastItem(message: "Name can not be empty", status: .failure)
                        return
                    }
                    
                    // Save changes
                    if !self.editSheetViewModel.is_locked {
                        self.albumViewModel.change_password(for: self.album, with: "")
                    } else if !self.editSheetViewModel.initial_password.isEmpty {
                        self.albumViewModel.change_password(for: self.album, with: self.editSheetViewModel.initial_password)
                    }
                    
                    if !self.editSheetViewModel.did_album_name_change(from: self.album) {
                        self.albumViewModel.change_name(for: self.album, with: trimmed)
                    }
                    
                    self.dismiss()
                    self.editModeActive = false
                } label: {
                    Text("Done")
                        .foregroundStyle(Color.c1_text)
                        .font(.system(size: 17,design: .rounded))
                        .padding(.horizontal,12)
                        .padding(.vertical,8)
                }
                .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 10),color: Color.c1_accent, isInteractive: true)
                .disabled(!self.editSheetViewModel.hasChanges(from: album))
                .opacity(self.editSheetViewModel.hasChanges(from: album) ? 1 : 0.3)
            }
            .overlay {
                Text("Edit Album")
                    .font(.system(size: 26,weight: .bold,design: .rounded))
                    .foregroundStyle(Color.c1_text)
            }
            .padding()
            //.frame(height: 50)
            
            VStack(spacing: 8) {
                Menu {
                    Button {
                        self.albumViewModel.change_upload_status(for: album, with: .Last)
                    } label: {
                        Text("Set to Last Image")
                    }
                    Button {
                        self.albumViewModel.change_upload_status(for: album, with: .First)
                    } label: {
                        Text("Set to First Image")
                    }
                    
                    Button {
                        self.showingPhotosPicker.toggle()
                    } label: {
                        Text("Choose From Own Library")
                    }
                } label: {
                    AlbumImageDisplay(album: album, corner_radius: 12)
                        .overlay(alignment: .bottom) {
                            Text("Tap To Edit")
                                .frame(maxWidth: .infinity)
                                .background(.black.opacity(0.5))
                                .foregroundStyle(Color.c1_text)
                        }
                        .frame(width: 150,height: 150)
                    
                }
                .photosPicker(isPresented: $showingPhotosPicker, selection: $avatar, matching: .images)
                
                Text("Choose first, last, or a photo from your library")
                    .font(.system(size: 16,weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.c1_text)
                    .opacity(0.75)
            }
            .padding(.bottom,25)
            
            VStack {
                // Change Name
                HStack {
                    Text("Name")
                        .frame(maxWidth: .infinity,alignment: .leading)
                        .font(.system(size: 18,weight: .semibold,design: .rounded))
                        .foregroundStyle(Color.c1_text)
                    
                    TextField(self.editSheetViewModel.album_name, text: self.$editSheetViewModel.album_name)
                        .font(.system(size: 15, design: .rounded))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .foregroundStyle(Color.c1_text) // White typed text
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.c1_primary).opacity(0.5) // 3. Applies the custom color
                        )
                        .padding(2)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.sentences)
                }
                .padding(5)
                Divider()
                //Password Toggler
                VStack {
                    Toggle(isOn: self.$editSheetViewModel.is_locked) {
                        Text("Lock Album")
                            .font(.system(size: 18,weight: .semibold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    .padding(5)
                    
                    if self.editSheetViewModel.is_locked {
                        Divider()
                        
                        HStack {
                            Text("Password")
                                .frame(maxWidth: .infinity,alignment: .leading)
                                .font(.system(size: 18,weight: .semibold,design: .rounded))
                                .foregroundStyle(Color.c1_text)
                           
                            TextField("Enter Password", text: self.$editSheetViewModel.initial_password, onEditingChanged: { editing_changed in
                                if editing_changed {
                                    self.editSheetViewModel.has_user_started_typing_initial = false
                                }
                            })
                                .font(.system(size: 15, design: .rounded))
                                .textFieldStyle(.plain)
                                .padding(8)
                                .foregroundStyle(Color.c1_text) // White typed text
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.c1_primary).opacity(0.5) // 3. Applies the custom color
                                )
                                .padding(2)
                                .autocorrectionDisabled()
                                .onChange(of: self.editSheetViewModel.initial_password) { old, new in
                                    self.editSheetViewModel.reset_initial(with: new)
                                }
                            }
                        .padding(5)

                        Text("PhotoSafe cannot recover album passwords in this version. If you forget this password, the album will stay locked.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.c1_text.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 5)
                            .padding(.bottom, 5)
                        
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.c1_primary).opacity(0.5))
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                // show delete alert
                self.showDeleteAlert = true
            } label: {
                Text("Delete Album")
                    .font(.system(size: 18,weight: .semibold,design: .rounded))
                    .foregroundStyle(Color.c1_text)
                    .padding(.horizontal,10)
                    .padding(.vertical,8)
            }
            .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 13), color: .red.opacity(0.75), isInteractive: true)
        }
        .alert("Delete \(album.name) album?", isPresented: self.$showDeleteAlert) {
            Button(role: .destructive) {
                do {
                    try self.albumViewModel.delete(album: album)
                    self.favoritesViewModel.setFavorites()
                    self.toast = ToastItem(message: "Successfully Deleted", status: .success)
                    self.dismiss()
                    self.editModeActive = false 
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
        .background(Color.c1_background)
        .onChange(of: self.editSheetViewModel.is_locked) {
            self.editSheetViewModel.reset_password()
        }
        .onChange(of: self.avatar, { old, new in
            guard let new else { return }
            Task {
                do {
                    guard let imageData = try await new.loadTransferable(type: Data.self) else {
                        await MainActor.run {
                            toast = ToastItem(message: "Failed to update cover for album", status: .failure)
                            self.avatar = nil
                        }
                        return
                    }
                    
                    await MainActor.run {
                        editSheetViewModel.selectedCoverData = imageData
                        editSheetViewModel.selectedCoverStatus = .Upload
                        self.avatar = nil
                    }
                } catch {
                    toast = ToastItem(message: "Failed to update cover for album", status: .failure)
                    self.avatar = nil
                }
            }
        })
        .onAppear {
            self.editSheetViewModel.set_variables(from: self.album)
        }
        .displayToast(self.$toast)
    }
}
