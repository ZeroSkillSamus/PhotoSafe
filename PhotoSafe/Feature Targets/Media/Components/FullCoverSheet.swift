//
//  FullCoverSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI
import AVKit
import SDWebImageSwiftUI

struct FullCoverSheet: View {
    @Environment(\.dismiss) var dismiss

    var select_media: SelectMediaEntity
    var list: [SelectMediaEntity]
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "x.circle")
                            .font(.title3)
                        
                    }
                    .foregroundStyle(.red)
                    
                    Spacer()
                    
                    Button {
                        print("Edit")
                    } label: {
                        Text("Edit")
                    }
                    .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: 60,alignment: .topLeading)
                .padding(5)
                .overlay(alignment: .top) {
                    if let first_index = self.list.firstIndex(of: self.select_media) {
                        Text("\(first_index + 1) of \(list.count)")
                            .font(.title3)
                            .padding(5)
                            .foregroundStyle(.primary)
                    }
                }
 
                VStack {
                    switch select_media.media.type {
                    case MediaType.Photo.rawValue:
                        if let image = select_media.media.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    case MediaType.Video.rawValue:
                        if let video_path = select_media.media.video_path, let url = URL(string: video_path) {
                            VideoPlayer(player: AVPlayer(url: url))
                        }
                    case MediaType.GIF.rawValue:
                        AnimatedImage(data: select_media.media.image_data)
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
