//
//  MediaDisplay.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/28/25.
//

import SwiftUI
import PhotosUI
import AVKit
import SDWebImageSwiftUI

enum MediaType: String {
    case Photo = "Photo"
    case Video = "Video"
    case GIF = "GIF"
}

struct SelectMediaEntity: Hashable {
    enum Select {
        case checked
        case blank
    }
    
    var media: MediaEntity
    var select: Select = .blank
}

struct FullScreenModalView: View {
    @Environment(\.dismiss) var dismiss

    var media: MediaEntity
    var list: [SelectMediaEntity]
    
    var body: some View {
        ZStack {
            VStack {
                Button {
                   dismiss()
                } label: {
                   Image(systemName: "x.circle")
                        .font(.title)
                        
                }
                .frame(maxWidth: .infinity, maxHeight: 60,alignment: .topLeading)
                .foregroundStyle(.primary)
                .padding(5)
                
                VStack {
                    switch media.type {
                    case MediaType.Photo.rawValue:
                        if let image = media.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    case MediaType.Video.rawValue:
                        if let video_path = media.video_path, let url = URL(string: video_path) {
                            VideoPlayer(player: AVPlayer(url: url))
                        }
                    case MediaType.GIF.rawValue:
                        AnimatedImage(data: media.image_data)
                            .resizable()
                            .customLoopCount(0)
                            .scaledToFit()
                            
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity)
            }
            .padding(5)
        }
        .preferredColorScheme(.dark)
    }
}

struct MediaDisplayView: View {
    var album: AlbumEntity
    @ObservedObject var album_vm: AlbumViewModel
    
    @State private var media_selected: [PhotosPickerItem] = []
    @State private var isPresented = false
    @State private var album_media: [SelectMediaEntity] = []
 
    @State private var photo_count: Int = 0
    @State private var video_count: Int = 0

    @State private var is_selected: Bool = false
    var gridItemLayout = Array(repeating: GridItem(.flexible(minimum: 40), spacing: 3), count: 4)

    @State private var select_count: Int = 0
    @State var selectedItem: MediaEntity?
    
    func determine_color(media: SelectMediaEntity) -> Color {
        if self.is_selected {
            switch media.select {
            case .blank:
                return .clear
            case .checked:
                return .green
            }
        } else {
            return .clear
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
                        
                        Text("Photos: \(self.photo_count), Videos: \(self.video_count)")
                            .font(.system(size: 13,weight: .semibold,design: .rounded))
                    }
                }

                LazyVGrid(columns: gridItemLayout, spacing: 3) {
                    ForEach(Array(self.album_media.enumerated()), id: \.offset) { index, file in
                        if let ui_image = self.album_media[index].media.image {
                            Image(uiImage: ui_image)
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .scaleEffect(1.3)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(alignment: .topLeading) {
                                    VStack {
                                        if file.media.type == MediaType.Video.rawValue {
                                            Image(systemName: "video.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(5)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(determine_color(media: file), lineWidth: 2)
                                )
                                .onTapGesture {
                                    if is_selected {
                                        switch file.select {
                                        case .blank:
                                            self.album_media[index].select = .checked
                                            self.select_count = select_count + 1
                                        case .checked:
                                            self.album_media[index].select = .blank
                                            self.select_count = select_count - 1
                                        }
                                    } else {
                                        self.selectedItem = file.media
                                    }
                                }
                                
                        }
                    }
                }
            }
            
            if !is_selected {
                // Bottom Header
                PhotosPicker(selection: self.$media_selected, selectionBehavior: .ordered) {
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
                    SelectBottomButton(label: "Delete", system_name:"trash")
                        .foregroundStyle(.red)
                    //.background(.green)
                    
                    Spacer()
                    
                    SelectBottomButton(label: "Export", system_name:"square.and.arrow.up")
                        .foregroundStyle(.white)
                    //.background(.blue)
                    
                    Spacer()
                    
                    SelectBottomButton(label: "Select All", system_name:"scope")
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    SelectBottomButton(label: "Move", system_name:"folder")
                        .foregroundStyle(.white)
                    //.background(.red)
                }
                .padding(.horizontal)
                .padding(.vertical,10)
                .frame(maxWidth: .infinity, maxHeight: 45,alignment: .center)
                .background(.bar)
            }
        }
        .fullScreenCover(item: $selectedItem) { item in
            FullScreenModalView(media: item, list: self.album_media)
        }
        .onAppear {
            // Load Photos
            if let media = album.media, let album_media = media.allObjects as? [MediaEntity] {
                let sorted_media = album_media.sorted(by: { a, b in
                    a.date_added < b.date_added
                })
                
                self.album_media = sorted_media.map { element in
                    SelectMediaEntity(media: element)
                }
                
                
                self.photo_count = self.album_media.filter({$0.media.type == MediaType.Photo.rawValue}).count
                self.video_count = self.album_media.filter({$0.media.type == MediaType.Video.rawValue}).count
            }
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
                    if !self.album_media.isEmpty {
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
        .onChange(of: self.media_selected) {
            Task {
                for item in self.media_selected {
                    if let video_url = try? await item.loadTransferable(type: VideoFileTranferable.self)?.url {
                        if let thumbnail = video_url.generateVideoThumbnail() {
                            let media = self.album_vm.add_media(
                                album: self.album,
                                type: MediaType.Video,
                                image_data: thumbnail,
                                video_path: video_url.absoluteString
                            )
                            
                            self.album_media.append(SelectMediaEntity(media: media))
                            self.video_count = self.video_count + 1
                        }
                    }
                    else if let image_data = try? await item.loadTransferable(type: Data.self) {
                        // Code determines if image is either a gif
                        let supported_types = item.supportedContentTypes
                        let isGIF = supported_types.contains(UTType.gif)
                        let type = isGIF ? MediaType.GIF : MediaType.Photo
                        
                        let media = self.album_vm.add_media(album: self.album, type: type, image_data: image_data)
                        self.album_media.append(SelectMediaEntity(media: media))
                        self.photo_count = self.photo_count + 1
                        
                    }
                }
            }
        }
    }
    
    struct SelectBottomButton: View {
        var label: String
        var system_name: String
        
        
        var body: some View {
            Button {
                print("Delete")
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

struct VideoFileTranferable: Transferable {
    let url: URL

    static var get_application_support_dir: URL {
        let urls = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        let appSupportURL = urls.first!
        
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appSupportURL.path) {
            try? FileManager.default.createDirectory(
                at: appSupportURL,
                withIntermediateDirectories: true
            )
        }
        return appSupportURL
    }
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { file in
            // Use COPY instead of MOVE to preserve original
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try FileManager.default.copyItem(at: file.url, to: tempURL)
            return SentTransferredFile(tempURL)
        } importing: { received in
            // 1. Get Application Support directory
            let appSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            
            // 2. Create Videos subdirectory if needed
            let videosDir = appSupportURL.appendingPathComponent("Videos")
            try? FileManager.default.createDirectory(
                at: videosDir,
                withIntermediateDirectories: true
            )
            
            // 3. Create permanent destination URL
            var permanentURL = videosDir
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            // 4. COPY (not move) from received location
            try FileManager.default.copyItem(at: received.file, to: permanentURL)

            // 5. Clean up: Remove the temporary file
            try? FileManager.default.removeItem(at: received.file)
            
            // 6. Mark as non-temporary for persistence
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            try? permanentURL.setResourceValues(resourceValues)
            
            return Self(url: permanentURL)
        }
    }
}

extension URL {
    func generateVideoThumbnail() -> Data? {
        let asset = AVAsset(url: self)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 60), actualTime: nil)
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 1)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}
