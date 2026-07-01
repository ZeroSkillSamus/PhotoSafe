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
    @State private var toast: ToastItem?
    @Binding var path: NavigationPath
    
    private struct AlbumVerticalDisplay: View {
        @State private var display_alert: Bool = false
        @State private var password: String = ""
        @State private var album_selected_to_edit: AlbumEntity?
        
        @Binding var toast: ToastItem?
        @Binding var is_edit_enabled: Bool
        @Binding var path: NavigationPath
        var album: AlbumEntity
        
        private func handleAlbumTap() {
            if self.is_edit_enabled { return }
            if album.is_locked {
                self.display_alert = true
                self.password = "" //Clear password anytime the alert pops up
            } else {
                path.append(album)
            }
        }
        
        private func handleEditTap() {
            if album.is_locked {
                self.display_alert = true
                self.password = "" //Clear password anytime the alert pops up
            } else {
                self.album_selected_to_edit = album
            }
        }
        
        var body: some View {
            AlbumVDisplay(
                album: album,
                toast: self.$toast,
                isEditModeEnabled: self.$is_edit_enabled,
                openAction: self.handleAlbumTap,
                editAction: self.handleEditTap
            )
            .fullScreenCover(item: $album_selected_to_edit) { album in
                AlbumEditView(album: album, editModeActive: self.$is_edit_enabled)
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
    
    var albumCountText: Text {
        let count = album_VM.albums.count
        if count == 0 { return Text("No private collections yet") }
        return Text("^[\(count) private collection](inflect: true)")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NewHeaderView(
                title: "Albums",
                trailingButtons: {
                    Button {
                        withAnimation {
                            self.is_edit_enabled.toggle()
                        }
                    } label: {
                        Text(self.is_edit_enabled ? "Cancel" : "Edit")
                            .foregroundStyle(Color.c1_text)
                            .font(.system(size: 17,design: .rounded))
                            .padding(.horizontal,12)
                            .padding(.vertical,8)
                    }
                    .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 10),color: Color.c1_accent, isInteractive: true)
                    .disabled(self.album_VM.albums.isEmpty)
                    .opacity(self.album_VM.albums.isEmpty ? 0.3 : 1)
                },
                subtitle: self.albumCountText
            )
            
            if album_VM.albums.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack.fill.badge.plus")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(Color.c1_accent)

                    VStack(spacing: 10) {
                        Text("Create your first private album")
                            .font(.system(size: 25, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.c1_text)
                        
                        Text("Tap + below to create an album or import media.")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.c1_text.opacity(0.85))

                        Text("Albums keep photos, videos, and saved web media organized behind your PhotoSafe lock.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.c1_text.opacity(0.65))
                    }
                    .padding(.horizontal, 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 9) {
                        ForEach(self.album_VM.albums, id:\.self) { album in
                            AlbumVerticalDisplay(
                                toast: self.$toast,
                                is_edit_enabled: self.$is_edit_enabled,
                                path: self.$path,
                                album: album
                            )
                        }
                    }
                    .padding(.top, 18)
                    .padding(.horizontal)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: self.album_VM.albums.isEmpty)
        .displayToast(self.$toast)
    }
}
