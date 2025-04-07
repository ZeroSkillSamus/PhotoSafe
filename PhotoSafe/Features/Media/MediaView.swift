//
//  MediaDisplay.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/28/25.
//

import SwiftUI
import PhotosUI


enum MediaType: String {
    case Photo = "Photo"
    case Video = "Video"
    case GIF = "GIF"
}

struct MediaView: View {
    @ObservedObject var album: AlbumEntity
    
    @StateObject private var media_VM: MediaViewModel = MediaViewModel()

    @State private var is_select_all: Bool = false
    @State private var select_count: Int = 0
    @State private var selectedItem: SelectMediaEntity?
    @State private var is_select_mode_active: Bool = false
    @State private var selected_media: [PhotosPickerItem] = []
  
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
                    }
                    .padding(.top,5)
                }

                LazyVGrid(columns: gridItemLayout, spacing: 3) {
                    ForEach(self.$media_VM.medias) { $media_select in
                        ImageGridView(
                            is_selected: self.is_select_mode_active,
                            media_select: $media_select,
                            selected_item: self.$selectedItem,
                            select_count: self.$select_count
                        )
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
                    is_selected: self.$is_select_mode_active,
                    num_selected_items:self.$select_count,
                    album: self.album,
                    media_VM: self.media_VM
                )
            }
        }
        .overlay(alignment: .center) {
            if self.media_VM.display_alert {
                VStack(spacing: 15) {
                    VStack(spacing: 5) {
                        Text("Progress")
                            .font(.title3.bold())
                        
                        Text("\(Int(self.media_VM.alert_value))/\(self.selected_media.count)")
                            .font(.footnote.bold())
                    }
                    
                    ProgressView(value: self.media_VM.alert_value,total: Float(self.selected_media.count))
                        .progressViewStyle(.linear)
                        .padding(.horizontal)
                }
                .padding(.vertical, 25)
                .frame(maxWidth: 270)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
        }
        .background{
            if self.media_VM.display_alert {
                Color.black.opacity(0.35)
            }
        }
        .fullScreenCover(item: $selectedItem) { item in
            FullCoverSheet(select_media: item, list: self.media_VM.medias)
        }
        .onAppear {
            self.media_VM.set_media_and_counts(from: album)
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
