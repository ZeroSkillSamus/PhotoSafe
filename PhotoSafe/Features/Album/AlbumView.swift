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

        @Binding var is_edit_enabled: Bool
        @Binding var path: NavigationPath
        var album: AlbumEntity
        
        var body: some View {
            if !self.is_edit_enabled {
                Group {
                    if album.is_locked {
                        Button {
                            self.display_alert = true
                            self.password = "" //Clear password anytime the alert pops up
                        } label: {
                            AlbumVDisplay(album: album,is_edit_enabled: self.$is_edit_enabled)
                        }
                        .alert("Enter Password For \(album.name)",
                               isPresented: self.$display_alert)
                        {
                            TextField("Enter Your Password", text: self.$password)
                                .foregroundStyle(.black)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .textContentType(.password)
                            
                            Button("OK", role: .cancel) {
                                if let album_password = album.password,
                                   album_password == password {
                                    path.append(album)
                                }
                            }
                        }
                    } else {
                        NavigationLink(value: album) {
                            AlbumVDisplay(album: album, is_edit_enabled: self.$is_edit_enabled)
                        }
                        
                    }
                    Divider()
                }
            } else {
                

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
