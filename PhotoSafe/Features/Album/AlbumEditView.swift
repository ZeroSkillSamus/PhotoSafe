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
    @StateObject private var edit_sheet_VM: EditSheetViewModel = EditSheetViewModel()
    
    @EnvironmentObject private var album_VM: AlbumViewModel
    @Environment(\.dismiss) var dismiss
    
    var album: AlbumEntity
    @State private var avatar: PhotosPickerItem?
    @State private var showingPhotosPicker: Bool = false
    @State private var error: Bool = false
   
    var body: some View {
        VStack {
            // Header
            HStack {
                Spacer()
                
                Button {
                    // Save changes
                    if self.album.password != self.edit_sheet_VM.initial_password {
                        self.album_VM.change_password(for: self.album, with: self.edit_sheet_VM.initial_password)
                    }
                    
                    if !self.edit_sheet_VM.did_album_name_change(from: self.album) {
                        self.album_VM.change_name(for: self.album, with: self.edit_sheet_VM.album_name)
                    }
                    
                    self.dismiss()
                    
                    
                } label: {
                    Text("Done")
                        .foregroundStyle(Color.c1_text)
                        .font(.footnote.bold())
                }
                
            }
            .overlay {
                Text("Edit Album")
                    .font(.title2.bold())
                    .foregroundStyle(Color.c1_text)
            }
            .padding()
            .frame(height: 50)
            
            
            Menu {
                Button {
                    self.album_VM.change_upload_status(for: album, with: .Last)
                } label: {
                    Text("Set to Last Image")
                }
                Button {
                    self.album_VM.change_upload_status(for: album, with: .First)
                } label: {
                    Text("Set to First Image")
                }
                
                Button {
                    self.showingPhotosPicker.toggle()
                } label: {
                    Text("Choose From Own Library")
                }
            } label: {
                AlbumImageDisplay(album: album, corner_radius: 6)
                    .overlay(alignment: .bottom) {
                        Text("Tap To Edit")
                            .frame(maxWidth: .infinity)
                            .background(.black.opacity(0.5))
                            .foregroundStyle(Color.c1_text)
                    }
                    .frame(width: 130,height: 130)
                
            }
            .photosPicker(isPresented: $showingPhotosPicker, selection: $avatar, matching: .images)
            
            // Change Name
            HStack {
                Text("Name")
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .font(.title3)
                    .foregroundStyle(Color.c1_text)
                
                TextField(self.edit_sheet_VM.album_name, text: self.$edit_sheet_VM.album_name)
                    .opacity(0.5)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    .foregroundStyle(Color.c1_text)
                    .background(Color.c1_background)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .onChange(of: self.edit_sheet_VM.album_name) {
                        self.edit_sheet_VM.remove_last_from_album_name()
                    }
                
            }
            .padding()
            
            //Password Toggler
            VStack {
                Toggle(isOn: self.$edit_sheet_VM.is_locked) {
                    Text("Password")
                        .font(.title3)
                        .foregroundStyle(Color.c1_text)
                }
                .padding()
                
                if self.edit_sheet_VM.is_locked {
                    HStack {
                        Text("Initial Password")
                            .frame(maxWidth: .infinity,alignment: .leading)
                            .font(.title3)
                            .foregroundStyle(Color.c1_text)

                        TextField("Enter Password", text: self.$edit_sheet_VM.initial_password, onEditingChanged: { editing_changed in
                            if editing_changed {
                                self.edit_sheet_VM.has_user_started_typing_initial = false
                            }
                        })
                            .opacity(0.75)
                            .textInputAutocapitalization(.never)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                            .foregroundStyle(Color.c1_text)
                            .background(Color.c1_background)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .onChange(of: self.edit_sheet_VM.initial_password) { old, new in
                                self.edit_sheet_VM.reset_initial(with: new)
                            }
                        }
                    .padding()
                    
                }
            }
            Spacer()
            
        }
        .background(Color.c1_background)
        .onChange(of: self.edit_sheet_VM.is_locked) {
            self.edit_sheet_VM.reset_password()
        }
        .alert("Passwords Do Not Match!", isPresented: self.$error) {
            Button {} label: { Text("Ok") }
        }
        .onChange(of: self.avatar) {
            Task {
                if let image_data = try? await self.avatar?.loadTransferable(type: Data.self) {
                    self.album_VM.change_image(for: album, with: image_data)
                    self.album_VM.change_upload_status(for: album, with: .Upload)
                    self.avatar = nil
                } else {
                    self.album_VM.change_upload_status(for: album, with: .None)
                }
            }
        }
        .onAppear {
            self.edit_sheet_VM.set_variables(from: self.album)
        }
    }
}
