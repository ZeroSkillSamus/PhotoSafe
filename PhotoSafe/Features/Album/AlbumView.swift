//
//  ContentView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/25/25.
//
import SwiftUI

struct AlbumView: View {
    @EnvironmentObject private var album_VM: AlbumViewModel
    @State private var display_alert: Bool = false
    @State private var is_edit_enabled: Bool = false
    @Binding var path: NavigationPath
    
    private struct AlbumVerticalDisplay: View {
        @State private var display_alert: Bool = false
        @State private var password: String = ""
        @State private var album_selected_to_edit: AlbumEntity?
        
        @Binding var is_edit_enabled: Bool
        @Binding var path: NavigationPath
        var album: AlbumEntity
        
        var body: some View {
            Button {
                if album.is_locked {
                    self.display_alert = true
                    self.password = "" //Clear password anytime the alert pops up
                } else if self.is_edit_enabled {
                    self.album_selected_to_edit = album
                } else {
                    path.append(album)
                }
            } label: {
                AlbumVDisplay(album: album,is_edit_enabled: self.$is_edit_enabled)
            }
            .fullScreenCover(item: $album_selected_to_edit) { album in
                AlbumEditView(album: album)
            }
            .alert("Enter Password For \(album.name)",
                   isPresented: self.$display_alert)
            {
                TextField("Enter Your Password", text: self.$password)
                    .foregroundStyle(Color.c1_text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textContentType(.password)
                
                Button("OK", role: .cancel) {
                    if album.password == password {
                        if self.is_edit_enabled {
                            self.album_selected_to_edit = album
                        } else {
                            path.append(album)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopHeader(album_vm: self.album_VM, is_edit_enabled: self.$is_edit_enabled)
            
            if self.album_VM.albums.isEmpty {
                Text("Press '+' To Create an Album!!")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .center)
                    .foregroundStyle(Color.c1_text)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(self.album_VM.albums, id:\.self) { album in
                            AlbumVerticalDisplay(
                                is_edit_enabled: self.$is_edit_enabled,
                                path: self.$path,
                                album: album
                            )
                        }
                    }
                }
            }
        }
    }
}
