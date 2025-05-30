//
//  MediaDisplay.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/28/25.
//

import SwiftUI
import PhotosUI
import CoreData

enum MediaType: String {
    case Photo = "Photo"
    case Video = "Video"
    case GIF = "GIF"
}

struct MediaView: View {
    @EnvironmentObject private var favorite_VM: FavoriteViewModel
    
    @ObservedObject var album: AlbumEntity
    @StateObject private var media_VM: MediaViewModel = MediaViewModel()

    @State private var is_select_all: Bool = false
    @State private var select_count: Int = 0
    @State private var selectedItem: SelectMediaEntity?
    @State private var is_select_mode_active: Bool = false
    @State private var selected_media: [PhotosPickerItem] = []
    @State private var sheet_media_index: Int = 0
    @State private var display_move_sheet: Bool = false
    
    /// If we are in select mode function will handle if a user taps on a photo it will highlight green for selected items
    /// User can tap the media again to uncheck the item
    /// If we are not in select mode we then set the selected_item, which will open our sheet
    private func handle_select_image(for select_media: inout SelectMediaEntity) {
        if self.is_select_mode_active {
            switch select_media.select {
            case .blank:
                select_media.select = .checked
                self.select_count = select_count + 1
            case .checked:
                select_media.select = .blank
                self.select_count = select_count - 1
            }
        } else {
            self.selectedItem = select_media
        }
    }
    
    var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 3), count: 4)
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if !self.is_select_mode_active {
                    VStack(spacing: 5) {
                        AlbumImageDisplay(album: self.album)
                            .frame(width: 150, height:150)
                            .clipShape(Circle())
                        
                        Text("Photos: \(self.media_VM.photo_count), Videos: \(self.media_VM.video_count)")
                            .font(.system(size: 13,weight: .semibold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                        
                    }
                    .padding(.top,5)
                }

                LazyVGrid(columns: gridItemLayout, spacing: 3) {
                    ForEach(self.$media_VM.medias) { $select_media in
                        if let ui_image = select_media.media.thumbnail_image {
                            MediaImageGridView(
                                is_select_mode_active: self.is_select_mode_active,
                                ui_image: ui_image,
                                media_select: $select_media,
                                selected_media: self.$selectedItem,
                                select_count: self.$select_count
                            )
                        }
                    }
                }
                .padding(.top,10)
                
                Color.clear  // Add extra space to the bottom of the view
                    .frame(height: 50)
            }
            .overlay(alignment: .bottom) {
                // Bottom Header
                BottomHeader(
                    selected_media: self.$selected_media,
                    select_mode_active: self.$is_select_mode_active,
                    num_selected_items:self.$select_count,
                    album: self.album,
                    media_VM: self.media_VM
                )
            }
        }
        .overlay(alignment: .center) {
            if self.media_VM.progress_alert {
                ProgressAlert(
                    selected_media_count: self.selected_media.count,
                    alert_value: self.media_VM.alert_value
                )
            } else if self.media_VM.export_finished {
                CustomAlertView {
                    Text("Save Finished")
                        .font(.title3.bold())
                }
            }
        }
        .background{
            if self.media_VM.progress_alert || self.media_VM.export_finished {
                Color.c1_background.opacity(0.35).ignoresSafeArea()
            } else {
                Color.c1_background.ignoresSafeArea(edges: .bottom)
            }
        }
        .toolbarBackground(Color.c1_background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .fullScreenCover(item: $selectedItem) { item in
            FullCoverSheet(
                from_where: .Media,
                media_VM: self.media_VM,
                select_media: item,
                list: self.$media_VM.medias
            )
        }
        .onAppear {
            self.media_VM.set_media_and_counts(from: album)
            
            // Load cache
            ImageCache.preloadImages(medias: self.media_VM.medias)
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .toolbar {
            // Title of Album
            ToolbarItem(placement: .principal) {
                VStack {
                    header
                        .font(.title2.bold())
                        .id("text-\(self.is_select_mode_active ? "Select Media" : album.name )")
                        .transition(.opacity) // Fade in/out
                        .animation(.easeInOut(duration: 0.35), value: self.is_select_mode_active)
                        .foregroundStyle(Color.c1_text)
                }
            }
            
            // Select Button that will allow user to select multiple
            // pieces of media
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if !self.media_VM.medias.isEmpty {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            self.is_select_mode_active.toggle()
                        }
                        
                        // Reset Everything To Blank
                        if self.is_select_mode_active {
                            self.media_VM.change_all(to: .blank)
                            self.select_count = 0
                        }
                    }
                } label: {
                    Text(self.is_select_mode_active ? "Finish" : "Select")
                }
            }
        }
    }
    
    var header: Text {
        if self.is_select_mode_active {
            if self.select_count == 0 {
                return Text("Select Media")
            } else {
                return Text("^[\(self.select_count) Item](inflect: true) Selected")
            }
        }
        return Text(self.album.name)
    }
}
