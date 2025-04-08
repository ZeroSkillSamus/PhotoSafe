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
    
    @State private var password: String = ""
  
    @Binding var path: NavigationPath
    var body: some View {
        VStack(spacing: 0) {
            TopHeader(album_vm: self.album_VM)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(self.album_VM.albums, id:\.self) { album in
                        if album.is_locked {
                            Button {
                                self.display_alert = true
                            } label: {
                                AlbumVDisplay(album: album)
                            }
                            .alert("Enter Password For \(album.name)",
                                   isPresented: self.$display_alert)
                            {
                                TextField("Enter Your Password", text: self.$password)
                                    .foregroundStyle(.white)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                
                                Button("OK", role: .cancel) {
                                    if let album_password = album.password,
                                        album_password == password {
                                        path.append(album)
                                    }
                                }
                            }
                        } else {
                            NavigationLink(value: album) {
                                AlbumVDisplay(album: album)
                            }
                        }
                        Divider()
                    }
                }
            }
           
            // Ensure Everything Starts At Top of Page
            Spacer()
        }
    }
}
