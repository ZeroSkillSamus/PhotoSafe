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
    
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var prev_orientation = UIDeviceOrientation.unknown
    
    @State private var current_media_index: Int = 0
    @State private var curr_media: SelectMediaEntity?
    @State var player_controller: AVPlayerViewController = AVPlayerViewController()
    
    var should_header_display: Bool {
        self.orientation.isPortrait || (self.orientation.isFlat && !self.prev_orientation.isLandscape) || self.orientation == .unknown
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if should_header_display {
                    HStack {
                        Button {
                            self.dismiss()
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
                    .padding(.horizontal,5)
                    .overlay(alignment: .top) {
                        Text("\(current_media_index + 1) of \(list.count)")
                            .font(.title3)
                            .padding(5)
                            .foregroundStyle(.primary)
                    }
                }
 
                TabView(selection: $current_media_index) {
                    ForEach(0..<list.count,id:\.self) { index in
                        VStack {
                            switch list[index].media.type {
                            case MediaType.Photo.rawValue:
                                if let image = list[index].media.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        
                                }
                            case MediaType.Video.rawValue:
                                if let video_path = list[index].media.video_path, let url = URL(string: video_path) {
                                    if self.current_media_index == index { // Needed to stop video from preloading due to TabView
                                        PlayerView(
                                            curr_orientation: self.orientation,
                                            prev_orientation: self.prev_orientation,
                                            url: url
                                        )
                                    }
                                }
                            case MediaType.GIF.rawValue:
                                AnimatedImage(data: list[index].media.image_data)
                                    .resizable()
                                    .customLoopCount(0)
                                    .scaledToFit()
                                
                            default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .onRotate { newOrientation in
                self.prev_orientation = self.orientation
                self.orientation = newOrientation
            }
        }
        .onAppear {
            self.current_media_index = self.list.firstIndex(of: self.select_media) ?? 0
        }
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
        .ignoresSafeArea(edges: .bottom)
    }
}
