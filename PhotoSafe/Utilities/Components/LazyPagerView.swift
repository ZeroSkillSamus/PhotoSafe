//
//  LazyPagerView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/11/26.
//

import SwiftUI
import LazyPager
import SDWebImageSwiftUI
import AVKit

struct LazyPagerView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var videoToDisplay: SelectMediaEntity? = nil
    var isDisplay: Bool = false
    
    var direction: SlideShowType = .horizontal
    
    @Binding var windowedList: [SelectMediaEntity]
    @Binding var windowListIndex: Int
    @Binding var backgroundOpacity: CGFloat
    @Binding var userTapped: Bool
    
    var directionDecoded: Direction {
        switch direction {
        case .vertical:
                .vertical
        case .horizontal:
                .horizontal
        }
    }
    
    private func image_view(_ ui_image: UIImage) -> some View {
        Image(uiImage: ui_image)
            .resizable()
            .scaledToFit()
    }
    
    struct AsyncPhotoView: View {
          let media: MediaEntity
          @State private var fullImage: UIImage? = nil

          var body: some View {
              Group {
                  if let fullImage {
                      Image(uiImage: fullImage)
                          .resizable()
                          .scaledToFit()
                  } else if let thumbnail = media.thumbnail_image {
                      Image(uiImage: thumbnail)
                          .resizable()
                          .scaledToFit()
                  }
              }
              .onChange(of: media.id) { _, newID in
                  if let cached = ImageCache.fetch_image(for: newID.uuidString) {
                      fullImage = cached
                  } else {
                      fullImage = nil
                  }
              }
              .task(id: media.id) {
                  let key = media.id.uuidString
                  let imageData = media.image_data
                  if let cached = ImageCache.fetch_image(for: key) {
                      fullImage = cached
                      return
                  }
                  let decoded = await Task.detached(priority: .userInitiated) {
                      ImageCache.set_image_and_return(data: imageData, key: key)
                  }.value
                  fullImage = decoded
              }
          }
      }
    
    struct GifView: View {
        @State private var isAnimating: Bool = true
        
        let element: SelectMediaEntity
        
        var body: some View {
            AnimatedImage(data: element.media.image_data, isAnimating: self.$isAnimating)
                .resizable()
                .customLoopCount(0)
                .scaledToFit()
                .onDisappear {
                    self.isAnimating = false
                }
                .onAppear {
                    self.isAnimating = true
                }
                
        }
    }
    
    struct VideoPlayerView: View {
          let url: URL
          @State private var player: AVPlayer?
          @Environment(\.dismiss) var dismiss
      
          var body: some View {
              ZStack(alignment: .topLeading) {
                  VideoPlayer(player: player ?? AVPlayer())
                      .ignoresSafeArea()

                  Button {
                      dismiss()
                  } label: {
                      Image(systemName: "xmark.circle.fill")
                          .font(.title)
                          .foregroundStyle(.white)
                          .shadow(radius: 4)
                  }
                  .ignoresSafeArea(edges: .horizontal)
                  .padding(.top, 12)
                  .padding(.leading, 2)
              }
              .onAppear {
                  player = AVPlayer(url: url)
                  player?.allowsExternalPlayback = false // disable airplay
                  
                  player?.play()
              }
              .onDisappear {
                  player?.pause()
                  player = nil
              }
          }
      }

    var body: some View {
        LazyPager(data: self.windowedList, page: self.$windowListIndex, direction: self.directionDecoded) { element in
            switch element.media.type {
            case MediaType.Photo.rawValue:
                AsyncPhotoView(media: element.media)
            case MediaType.Video.rawValue:
                if let thumbnail = element.media.thumbnail_image {
                    if isDisplay, let path = element.media.video_path, let url = URL(string: path) {
                        if self.windowedList[self.windowListIndex] == element { // needed to stop video from preloading
                            PlayerView(url: url)
                        }
                    } else {
                        image_view(thumbnail)
                            .overlay(alignment: .center) {
                                Button {
                                    self.videoToDisplay = element
                                } label: {
                                    ImageCircleOverlay(icon: .symbol("play.fill"))
                                }
                            }
                    }
                }
            case MediaType.GIF.rawValue:
                GifView(element: element)
            default:
                EmptyView()
            }
        }
            .zoomable(min: 1, max: 5)
            .onDismiss(backgroundOpacity: self.$backgroundOpacity) {
                self.dismiss()
            }
            .onTap { withAnimation { userTapped.toggle() } }
            .opacity(self.backgroundOpacity)
            .frame(maxWidth:.infinity,maxHeight: .infinity)
            .ignoresSafeArea(edges: [.bottom, .top])
            .fullScreenCover(item: self.$videoToDisplay) { video in
                if let video_path = video.media.video_path,
                   let url = URL(string: video_path) {
                    VideoPlayerView(url: url)
                }
             }
    }
}
