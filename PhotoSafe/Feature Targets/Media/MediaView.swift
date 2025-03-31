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
    var album: AlbumEntity
    @StateObject private var media_VM: MediaViewModel = MediaViewModel()

    @State private var media_selected: [PhotosPickerItem] = []
    @State private var isPresented = false
    @State private var select_count: Int = 0
    @State var selectedItem: SelectMediaEntity?
    @State private var is_selected: Bool = false
    
    var gridItemLayout = Array(repeating: GridItem(.flexible(minimum: 40), spacing: 3), count: 4)
    
    var body: some View {
        VStack {
            ScrollView {
                if !is_selected {
                    VStack(spacing: 5) {
                        if let image_data = album.image, let ui_image = UIImage(data: image_data) {
                            Image(uiImage: ui_image)
                                .resizable()
                                .frame(width: 150, height:150)
                                .scaledToFill()
                                .clipShape(Circle())
                        } else {
                            Image("NoImageFound")
                                .resizable()
                                .frame(width: 150, height:150)
                                .scaledToFill()
                                .clipShape(Circle())
                        }
                        
                        Text("Photos: \(self.media_VM.photo_count), Videos: \(self.media_VM.video_count)")
                            .font(.system(size: 13,weight: .semibold,design: .rounded))
                    }
                }

                LazyVGrid(columns: gridItemLayout, spacing: 3) {
                    ForEach(self.$media_VM.medias) { $media_select in
                        ImageGridView(
                            is_selected: self.is_selected,
                            media_select: $media_select,
                            selected_item: self.$selectedItem,
                            select_count: self.$select_count
                        )
                    }
                }
            }
            
            BottomHeader(
                is_selected: self.is_selected,
                album: self.album,
                media_VM: self.media_VM
            )
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
                        .id("text-\(self.is_selected ? "Select Media" : album.name )")
                        .animation(.easeInOut, value: self.is_selected)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Select Button that will allow user to select multiple
            // pieces of media
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if !self.media_VM.medias.isEmpty {
                        withAnimation(.easeInOut) {
                            self.is_selected.toggle()
                        }
                    }
                } label: {
                    Text(self.is_selected ? "Finish" : "Select")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    var header: Text {
        if self.is_selected {
            if select_count == 0 {
                return Text("Select Media")
            } else {
                return Text("^[\(self.select_count) Item](inflect: true) Selected")
            }
        }
        return Text(self.album.name)
    }
}
