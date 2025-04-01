//
//  BottomHeader.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI
import PhotosUI

struct BottomHeader: View {
    @State private var selected_media: [PhotosPickerItem] = []
    @State private var is_select_all: Bool = false
    @State private var is_move_sheet_active: Bool = false
    
    @Binding var is_selected: Bool
    var album: AlbumEntity
    
    @ObservedObject var media_VM: MediaViewModel
    var body: some View {
        VStack {
            if !self.is_selected {
                // Bottom Header
                PhotosPicker(selection: self.$selected_media, selectionBehavior: .ordered) {
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
                    SelectBottomButton(label: "Delete", system_name:"trash") {
                        withAnimation {
                            self.media_VM.delete_selected()
                            self.is_selected.toggle()
                        }
                    }
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
        .onChange(of: self.selected_media) {
            Task {
                for item in self.selected_media {
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

extension URL {
    func generateVideoThumbnail() -> Data? {
        let asset = AVAsset(url: self)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 10, preferredTimescale: 60), actualTime: nil)
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 1)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}

