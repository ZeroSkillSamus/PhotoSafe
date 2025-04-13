//
//  FullCoverSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI
import AVKit
import SDWebImageSwiftUI
import LazyPager

struct FullCoverSheet: View {
    @Environment(\.dismiss) var dismiss

    var select_media: SelectMediaEntity
    var list: [SelectMediaEntity]
    
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var prev_orientation = UIDeviceOrientation.unknown
    
    @State private var current_media_index: Int = 0
    @State private var curr_media: SelectMediaEntity?

    var should_header_display: Bool {
        self.orientation.isPortrait || (self.orientation.isFlat && !self.prev_orientation.isLandscape) || self.orientation == .unknown
    }

    @State private var did_user_tap: Bool = false
    
    @State private var opacity: CGFloat = 0
    
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
                    .frame(maxWidth: .infinity, maxHeight: 40,alignment: .topLeading)
                    .padding(.horizontal)
                    .overlay(alignment: .top) {
                        Text("\(current_media_index + 1) of \(list.count)")
                            .font(.title3)
                            .padding(5)
                            .foregroundStyle(.primary)
                    }
                    .background(Color.c1_secondary)
                    .opacity(self.opacity)
                    .opacity(!self.did_user_tap ? 1 : 0)
//                    .opacity(self.should_header_display ? 1 : 0)
                }
 
                LazyPager(data: self.list, page: self.$current_media_index) { element in
                    VStack {
                        switch element.media.type {
                        case MediaType.Photo.rawValue:
                            if let image = element.media.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            }
                        case MediaType.Video.rawValue:
                            if let video_path = element.media.video_path, let url = URL(string: video_path) {
                                //if self.current_media_index == elment. { // Needed to stop video from preloading
                                if list[self.current_media_index] == element {
                                    PlayerView(
                                        curr_orientation: self.orientation,
                                        prev_orientation: self.prev_orientation,
                                        url: url
                                    )
                                }
                            }
                        case MediaType.GIF.rawValue:
                            AnimatedImage(data: element.media.image_data)
                                .resizable()
                                .customLoopCount(0)
                                .scaledToFit()
                            //gif_view(index: index)
                        default:
                            EmptyView()
                        }
                        
                    }
                    //.ignoresSafeArea(edges: .bottom)
                }
                // Make the content zoomable
                .zoomable(min: 1, max: 5)
                .onDismiss(backgroundOpacity: $opacity) {
                    self.dismiss()
                }
                .onTap {
                    withAnimation {
                        self.did_user_tap.toggle()
                    }
                }
                .opacity(self.opacity)
                .frame(maxWidth:.infinity,maxHeight: .infinity)
                
                if should_header_display {
                    HStack {
                        SelectBottomButton(label: "Export", system_name: "square.and.arrow.up") {
                            print("DD")
                        }
                        .frame(maxWidth: .infinity)
                        
                        SelectBottomButton(label: "Vertical", system_name: "rectangle.expand.vertical") {
                            print("DD")
                        }
                        .frame(maxWidth: .infinity)
                        
                        SelectBottomButton(label: "Favorite", system_name: "heart") {
                            print("DD")
                        }
                        .frame(maxWidth: .infinity)
                        
                        SelectBottomButton(label: "Move", system_name: "rectangle.2.swap") {
                            print("DD")
                        }
                        .frame(maxWidth: .infinity)
                        
                        SelectBottomButton(label: "Delete", system_name: "trash") {
                            print("DD")
                        }
                        .frame(maxWidth: .infinity)
                        
                    }
                    .padding(.horizontal)
                    .background(Color.c1_secondary)
                    .opacity(self.opacity)
                    .opacity(!self.did_user_tap ? 1 : 0)
                }
            }
            .onRotate { newOrientation in
                self.prev_orientation = self.orientation
                self.orientation = newOrientation
            }
        }
        .onAppear {
            self.current_media_index = self.list.firstIndex(of: self.select_media) ?? 0
        }
        //.preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
        .background(.black.opacity(opacity))
        .background(ClearFullScreenBackground())
    }
}
