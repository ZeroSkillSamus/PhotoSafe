//
//  BottomHeader.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI
import PhotosUI

struct BottomHeader: View {
    @EnvironmentObject private var albumViewModel: AlbumViewModel
    
    @State private var is_select_all: Bool = false
    @State private var is_move_sheet_active: Bool = false
 
    @Binding var selected_media: [PhotosPickerItem]
    @Binding var select_mode_active: Bool
    @Binding var num_selected_items: Int
    
    var album: AlbumEntity
    
    @ObservedObject var media_VM: MediaViewModel
    
    struct BottomHeaderButton<Content: View>: View {
        @ViewBuilder var content: Content
        
        var body: some View {
            content
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    var isSelectMediaInAlbumEmpty: Bool {
        self.media_VM.selected_media.isEmpty
    }
    
    var buttonOpacity: Double {
        self.isSelectMediaInAlbumEmpty ? 0.3 : 1
    }
    
    var body: some View {
        VStack {
            if !self.select_mode_active {
                // Bottom Header
                PhotosPicker(selection: self.$selected_media, selectionBehavior: .ordered, photoLibrary: .shared()) {
                    ImageCircleOverlay()
                }
                
            } else {
                // Select Bottom Nav Bar
                HStack(alignment: .center) {
                    BottomHeaderButton {
                        SelectBottomButton(label: "Export", system_name:"square.and.arrow.up") {
                            Task {
                                await self.media_VM.exportSelectedMediaToPhotos()
                                
                                withAnimation {
                                    self.select_mode_active = false // Get out of select mode
                                }
                            }
                        }
                    }
                    .opacity(buttonOpacity)
                    .disabled(self.isSelectMediaInAlbumEmpty)
                    //Spacer()
                    BottomHeaderButton {
                        SelectBottomButton(label: !self.is_select_all ? "Select All" : "Deselect All", system_name:"scope") {
                            var selector = SelectMediaEntity.Select.checked
                            if self.is_select_all {
                                selector = .blank
                                self.num_selected_items = 0
                            } else {
                                self.num_selected_items = self.media_VM.medias.count
                            }
                            self.media_VM.change_all(to: selector)
                            
                            self.is_select_all.toggle()
                        }
                    }
                    
                    //Spacer()
                    BottomHeaderButton {
                        SelectBottomButton(label: "Move", system_name:"rectangle.2.swap"){
                            self.is_move_sheet_active.toggle()
                        }
                    }
                    .opacity(buttonOpacity)
                    .disabled(self.isSelectMediaInAlbumEmpty)
                    //.foregroundStyle(.white)
                    
                    //Spacer()
                    BottomHeaderButton {
                        SelectBottomButton(label: "Delete", system_name:"trash") {
                            withAnimation {
                                //TODO: - Handle error
                                try? self.media_VM.delete_selected()
                                self.albumViewModel.set_albums()
                                self.num_selected_items = 0
                                
                                // Only close select mode if the medias is empty after deleting
                                if self.media_VM.medias.isEmpty { self.select_mode_active.toggle() }
                            }
                        }
                    }
                    .opacity(buttonOpacity)
                    .disabled(self.isSelectMediaInAlbumEmpty)
                    //.foregroundStyle(.red)
                }
                .padding(.horizontal)
                .padding(.vertical,10)
                .frame(maxWidth: .infinity, maxHeight: 45,alignment: .center)
                .background(Color.c1_secondary)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: self.isSelectMediaInAlbumEmpty)
        .onChange(of: self.selected_media) {
            if selected_media.isEmpty { return }
            Task {
                await self.media_VM.add_imported_photos(to:album, from:self.selected_media)
                await MainActor.run {
                    self.selected_media.removeAll()
                    self.albumViewModel.set_albums()
                }
            }
        }
        .sheet(isPresented: self.$is_move_sheet_active, onDismiss: { self.selected_media = [] }) {
            MoveSheet(
                curr_album_name: self.album.name,
                itemCount: selected_media.count
            ) { album in
                self.num_selected_items = 0
                withAnimation {
                    self.media_VM.move_selected(to: album)
                    self.albumViewModel.set_albums()
                    // Only close select mode if medias is empty after moving
                    if self.media_VM.medias.isEmpty { self.select_mode_active.toggle() }
                }
            }
        }
    }
}

struct SelectBottomButton: View {
    var label: String
    var system_name: String
    
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: system_name)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width:18,height:18)

                Text(label)
                    .font(.system(size: 13, design: .rounded))
            }
            .foregroundStyle(Color.c1_primary)
        }
        .padding(.top,5)
        
    }
}
