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
    
    @EnvironmentObject private var album_VM: AlbumViewModel
    @Environment(\.dismiss) var dismiss
    
    var album: AlbumEntity
    @State private var avatar: PhotosPickerItem?
    @State private var showingPhotosPicker: Bool = false
    @State private var album_name: String = ""
    @State private var is_locked: Bool = false
    @State private var initial_password: String = ""
    @State private var repeated_password: String = ""
    
    @State private var has_user_started_typing_initial: Bool = false
    @State private var has_user_started_typing_repeated: Bool = false
    
    @State private var error: Bool = false
    
    private var passwords_match: Bool {
        initial_password == repeated_password
    }
    
    private var did_album_name_change: Bool {
        self.album.name == self.album_name
    }
    
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Spacer()
                
                Button {
                    // Save changes
//                    if !self.passwords_match && self.is_locked {
//                        self.error.toggle()
//                        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {   }
//                    } else {
//                        self.album_VM.change_password(for: self.album, with: self.initial_password)
//                        if !self.did_album_name_change {
//                            self.album_VM.change_name(for: self.album, with: self.album_name)
//                        }
//                        
//                        self.dismiss()
//                    }
                    
                } label: {
                    Text("Done")
                        .foregroundStyle(.white)
                        .font(.footnote.bold())
                }
                
            }
            .overlay {
                Text("Edit Album")
                    .font(.title2.bold())
            }
            .padding()
            .frame(height: 50)
            
            
            Menu {
                Button {
                    print("TBI")
                } label: {
                    Text("Set to Last Image")
                }
                Button {
                    print("TBI")
                } label: {
                    Text("Set to First Image")
                }
                
                Button {
                    self.showingPhotosPicker.toggle()
                } label: {
                    Text("Choose From Own Library")
                }
            } label: {
                AlbumImageDisplay(album: album)
                    .overlay(alignment: .bottom) {
                        Text("Tap To Edit")
                            .frame(maxWidth: .infinity)
                            .background(.black.opacity(0.5))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 120,height: 120)
                
            }
            .photosPicker(isPresented: $showingPhotosPicker, selection: $avatar, matching: .images)
            
            // Change Name
            HStack {
                Text("Name")
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .font(.title3)
                
                TextField(self.album_name, text: self.$album_name)
                    .opacity(0.5)
                    .multilineTextAlignment(.trailing)
                //.textInputAutocapitalization(type == .Name ? .words : .never)
                    .autocorrectionDisabled()
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    .foregroundStyle(.white)
                    .background(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .onChange(of: self.album_name) {
                        if self.album_name.count > 15 {
                            self.album_name.removeLast()
                        }
                    }
                
            }
            .padding()
            
            //Password Toggler
            VStack {
                Toggle(isOn: self.$is_locked) {
                    Text("Password")
                        .font(.title2)
                }
                .padding()
                
                if self.is_locked {
                    HStack {
                        Text("Initial Password")
                            .frame(maxWidth: .infinity,alignment: .leading)
                            .font(.title3)

                        TextField(self.initial_password, text: self.$initial_password, onEditingChanged: { editing_changed in
                            if editing_changed {
                                self.has_user_started_typing_initial = false
                            }
                        })
                            .opacity(0.5)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                            .foregroundStyle(.white)
                            .background(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .onChange(of: self.initial_password) { old, new in
                                if !self.has_user_started_typing_initial {
                                    self.initial_password = self.initial_password.isEmpty ? "" : String(new.last!)
                                    self.has_user_started_typing_initial = true
                                }
                                self.initial_password = String(repeating: "*", count: self.initial_password.count)
                            }
                        }
                    .padding()
                    
                    HStack {
                        Text("Retype Password")
                            .frame(maxWidth: .infinity,alignment: .leading)
                            .font(.title3)
                        
                        TextField(self.repeated_password, text: self.$repeated_password, onEditingChanged: { editing_changed in
                            if editing_changed {
                                self.has_user_started_typing_repeated = false
                            }
                        })
                            .opacity(0.5)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                            .foregroundStyle(.white)
                            .background(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .onChange(of: self.repeated_password) { old, new in
                                if !has_user_started_typing_repeated {
                                    self.repeated_password = self.repeated_password.isEmpty ? "" : String(new.last!)
                                    self.has_user_started_typing_repeated = true
                                }
                                self.repeated_password = String(repeating: "*", count: self.repeated_password.count)
                            }
                    }
                    .padding()
                }
            }
            //}
            
            Spacer()
            
        }
        .onChange(of: self.is_locked) {
            if !is_locked {
                self.initial_password = ""
                self.repeated_password = ""
            }
        }
        .alert("Passwords Do Not Match!", isPresented: self.$error) {
            Button {} label: { Text("Ok") }
        }
        .onChange(of: self.avatar) {
            Task {
                if let image_data = try? await self.avatar?.loadTransferable(type: Data.self) {
                    self.album_VM.change_image(for: album, with: image_data)
                    self.avatar = nil
                } else {
                    print("Failed")
                }
            }
        }
        .onAppear {
            self.album_name = self.album.name
            self.is_locked = self.album.is_locked
            
            self.initial_password = self.is_locked ? self.album.password : "Enter Password"
            self.repeated_password = self.is_locked ? self.album.password : "Retype Password"
            
        }
    }
}
