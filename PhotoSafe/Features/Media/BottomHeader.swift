//
//  BottomHeader.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI
import PhotosUI

struct BottomHeader: View {
    @State private var is_select_all: Bool = false
    @State private var is_move_sheet_active: Bool = false
 
    @Binding var selected_media: [PhotosPickerItem]
    @Binding var select_mode_active: Bool
    @Binding var num_selected_items: Int
    
    var album: AlbumEntity
    
    @ObservedObject var media_VM: MediaViewModel
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
                    SelectBottomButton(label: "Export", system_name:"square.and.arrow.up") {
                        self.media_VM.export_selected_media_to_photo_library()
                        withAnimation {
                            self.select_mode_active = false // Get out of select mode
                        }
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
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
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    SelectBottomButton(label: "Move", system_name:"rectangle.2.swap"){
                        self.is_move_sheet_active.toggle()
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    SelectBottomButton(label: "Delete", system_name:"trash") {
                        withAnimation {
                            self.media_VM.delete_selected()
                            self.num_selected_items = 0
                            
                            // Only close select mode if the medias is empty after deleting
                            if self.media_VM.medias.isEmpty { self.select_mode_active.toggle() }
                        }
                    }
                    .foregroundStyle(.red)
                }
                .padding(.horizontal)
                .padding(.vertical,10)
                .frame(maxWidth: .infinity, maxHeight: 45,alignment: .center)
                .background(.bar)
            }
        }
        .onChange(of: self.selected_media) {
            Task {
                await self.media_VM.add_imported_photos(to:album, from:self.selected_media)
                self.selected_media.removeAll()
            }
        }
        .sheet(isPresented: self.$is_move_sheet_active) {
            MoveSheet(
                media_VM: self.media_VM,
                curr_album_name: self.album.name
            ) { album in
                self.num_selected_items = 0
                withAnimation {
                    self.media_VM.move_selected(to: album)
                    
                    // Only close select mode if medias is empty after moving
                    if self.media_VM.medias.isEmpty { self.select_mode_active.toggle() }
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
                        .font(.title3)
                    Text(label)
                        .font(.caption.bold())
                }
            }
            .padding(.top,15)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
