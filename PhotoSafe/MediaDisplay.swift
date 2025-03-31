//
//  MediaDisplay.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/28/25.
//

import SwiftUI
import PhotosUI
import AVKit
//import AVFoundation

enum MediaType: String {
    case Photo = "Photo"
    case Movie = "Movie"
}

struct MediaDisplay: View {
    var album: AlbumEntity
    @ObservedObject var album_vm: AlbumViewModel
    
    @State private var media_selected: [PhotosPickerItem] = []
  
    @State private var album_media: [MediaEntity] = []
 
    @State private var photo_count: Int = 0
    @State private var video_count: Int = 0

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
                        
                        Text("Photos: \(self.photo_count), Videos: \(self.video_count)")
                            .font(.system(size: 13,weight: .semibold,design: .rounded))
                    }
                }

                LazyVGrid(columns: gridItemLayout, spacing: 3) {
                    ForEach(self.album_media, id: \.self) { media in
                        if let ui_image = media.image {
                            Image(uiImage: ui_image)
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .scaleEffect(1.3)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(alignment: .topLeading) {
                                    VStack {
                                        if media.type == MediaType.Movie.rawValue {
                                            Image(systemName: "video.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(5)
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
        .onAppear {
            // Load Photos
            if let media = album.media, let album_media = media.allObjects as? [MediaEntity] {
                self.album_media = album_media.sorted(by: { a, b in
                    a.date_added < b.date_added
                })
                
                self.photo_count = album_media.filter({$0.type == MediaType.Photo.rawValue}).count
                self.video_count = album_media.filter({$0.type == MediaType.Movie.rawValue}).count
            }
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .toolbar {
            // Title of Album
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(self.is_selected ? "Select Media" : album.name)
                        .font(.title2.bold())
                        .transition(.opacity) // Slides in/out
                        .id("text-\(self.is_selected ? "Select Media" : album.name )")
                }
                .frame(maxWidth: .infinity)
            }
            
            // Select Button that will allow user to select multiple
            // pieces of media
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeIn) {
                        self.is_selected.toggle()
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
                                type: MediaType.Movie,
                                image_data: thumbnail,
                                video_path: video_url.absoluteString
                            )
                            
                            self.album_media.append(media)
                            self.video_count = self.video_count + 1
                        }
                    }
                    else if let image_data = try? await item.loadTransferable(type: Data.self) {
                        let media = self.album_vm.add_media(album: self.album, type: MediaType.Photo, image_data: image_data)
                        self.album_media.append(media)
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
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try FileManager.default.copyItem(at: file.url, to: tempURL)
            return SentTransferredFile(tempURL)
        } importing: { received in
            // Define the destination in Application Support
            let appSupportURL = get_application_support_dir
            let videoURL = appSupportURL
                .appendingPathComponent("Videos")  // Optional subfolder
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            // Ensure the "Videos" subfolder exists
            try? FileManager.default.createDirectory(
                at: appSupportURL.appendingPathComponent("Videos"),
                withIntermediateDirectories: true
            )
            
            // Move the file (not copy) to Application Support
            try FileManager.default.moveItem(at: received.file, to: videoURL)
            
            return Self(url: videoURL)  // Return your model with the new URL
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
