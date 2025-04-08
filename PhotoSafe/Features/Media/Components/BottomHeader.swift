//
//  BottomHeader.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI
import PhotosUI

struct MoveSheet: View {
    @EnvironmentObject private var album_VM: AlbumViewModel
    
    @ObservedObject var media_VM: MediaViewModel
    var curr_album: AlbumEntity
    @Binding var num_selected_items: Int
    @Binding var select_mode_active: Bool
    
    @State private var toggle_alert: Bool = false
    @State private var album_name: String = ""
    @State private var album_password: String = ""
    
    struct MoveButtonLabel<Content: View>: View {
        let name: String
        let image: Content
        let action: () -> Void
        
        
        var body: some View {
            Button {
                self.action()
            } label: {
                HStack(spacing: 20) {
                    image
                        .frame(width: 60,height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    
                    Text(name)
                        .font(.system(size: 15,weight: .semibold,design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    
                    Image(systemName: "greaterthan")
                        .font(.system(size: 15,weight: .semibold,design: .rounded))
                        .foregroundStyle(.white)
                    
                }
                .frame(maxWidth: .infinity,alignment: .leading)
                .padding()
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Move Selected Media")
                    .font(.title2.bold())
            }
            .frame(maxWidth: .infinity,alignment: .leading)
            .padding()
            
            LazyVStack {
                ForEach(self.album_VM.albums.filter({$0.name != curr_album.name }),id:\.self) { album in
                    Button {
                        withAnimation {
                            self.media_VM.move_selected(to: album)
                            // Only close select mode if medias is empty after moving
                            if self.media_VM.medias.isEmpty { self.select_mode_active.toggle() }
                        }
                        
                        self.num_selected_items = 0
                    } label: {
                        HStack(spacing: 20) {
                            if let data = album.image, let ui_image = UIImage(data: data) {
                                Image(uiImage: ui_image)
                                    .resizable()
                                    .frame(width: 75,height: 75)
                                    .scaledToFill()
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            } else {
                                // Get first image from album if available
                                if let media = album.fetch_medias_as_list, let first = media.first, let ui_image = first.image {
                                    Image(uiImage: ui_image)
                                        .resizable()
                                        .frame(width: 75,height: 75)
                                        .scaledToFill()
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                } else {
                                    Image("NoImageFound")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 75,height: 75)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            }
                            
                            Text(album.name)
                            
                        }
                        .frame(maxWidth: .infinity,alignment: .leading)
                        .padding()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .presentationDetents([.medium, .medium, .fraction(0.35)])
    }
}


struct BottomHeader: View {
    @State private var is_select_all: Bool = false
    @State private var is_move_sheet_active: Bool = false
 
    @Binding var selected_media: [PhotosPickerItem]
    @Binding var is_selected: Bool
    @Binding var num_selected_items: Int
    
    var album: AlbumEntity
    
    @ObservedObject var media_VM: MediaViewModel
    var body: some View {
        VStack {
            if !self.is_selected {
                // Bottom Header
                PhotosPicker(selection: self.$selected_media, selectionBehavior: .ordered, photoLibrary: .shared()) {
                    ZStack {
                        Circle().fill(.blue)
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
                    .frame(width: 70,height: 70)
                }
                
            } else {
                // Select Bottom Nav Bar
                HStack(alignment: .center) {
                    SelectBottomButton(label: "Export", system_name:"square.and.arrow.up") {
                        self.media_VM.progress_alert = true
                        self.media_VM.export_selected_media_to_photo_library()
                        withAnimation {
                            self.is_selected = false // Get out of select mode
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
                    
                    SelectBottomButton(label: "Move", system_name:"folder"){
                        self.is_move_sheet_active.toggle()
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    SelectBottomButton(label: "Delete", system_name:"trash") {
                        withAnimation {
                            self.media_VM.delete_selected()
                            self.num_selected_items = 0
                            
                            // Only close select mode if the medias is empty after deleting
                            if self.media_VM.medias.isEmpty { self.is_selected.toggle() }
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
                self.media_VM.reset_alert_value()
                self.media_VM.progress_alert = true
                var asset_to_delete: [PHAsset] = []
                
                for item in self.selected_media {
                    // Handle adding to photos list which will be batched delete from user library
                    if let identifier = item.itemIdentifier, let asset = MediaHandler.fetchAsset(with: identifier) {
                        asset_to_delete.append(asset)
                    }
                    
                    // Handles Saving Media to CoreData
                    if let video_url = try? await item.loadTransferable(type: VideoFileTranferable.self)?.url {
                        if let thumbnail = video_url.generateVideoThumbnail() {
                            self.media_VM.add_media(
                                to: self.album,
                                type: MediaType.Video,
                                image_data: thumbnail,
                                video_path: video_url.absoluteString
                            )
                        }
                    }
                    else if let image_data = try? await item.loadTransferable(type: Data.self) {
                        // Code determines if image is either a gif
                        let supported_types = item.supportedContentTypes
                        let isGIF = supported_types.contains(UTType.gif)
                        let type = isGIF ? MediaType.GIF : MediaType.Photo
                        
                        self.media_VM.add_media(to: self.album, type: type, image_data: image_data)
                    }
                }
                
                // Batch delete
                MediaHandler.deleteAssets(asset_to_delete)
                
                // Done Looping, Time to Clear Out SelectedMedia
                self.selected_media.removeAll()
                self.media_VM.progress_alert = false
            }
        }
        .sheet(isPresented: self.$is_move_sheet_active) {
            MoveSheet(
                media_VM: self.media_VM,
                curr_album: self.album,
                num_selected_items: self.$num_selected_items,
                select_mode_active: self.$is_selected
            )
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
