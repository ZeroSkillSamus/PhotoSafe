//
//  VerticalMediaVIew.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/22/25.
//

import SwiftUI
import LazyPager
import SDWebImageSwiftUI

private func image_view(_ ui_image: UIImage) -> some View {
    Image(uiImage: ui_image)
        .resizable()
        .scaledToFit()
}

struct VerticalMediaVIew: View {
    @Environment(\.dismiss) var dismiss
    
    var list: [SelectMediaEntity]
    
    @State private var current_media_index: Int = 0
    @State private var new_list: [SelectMediaEntity] = []
    @State private var timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    @Binding var shuffle_list: Bool
    @Binding var time_interval: TimeInterval
    @Binding var auto_slide_enabled: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "x.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }

                    Spacer()
                    
                    Menu {
                        
                    } label: {
                        Image(systemName: "gear")
                            .renderingMode(.template)
                            .font(.title2)
                            .foregroundStyle(Color.c1_primary)
                    }
                }
                .overlay(alignment: .center, content: {
                    Text("\(current_media_index + 1) of \(list.count)")
                        .font(.title2)
                        .padding(5)
                        .foregroundStyle(Color.c1_text)
                })
                .padding(.horizontal)
                
                LazyPager(data: self.new_list,page: self.$current_media_index, direction: .vertical) { element in
                    switch element.media.type {
                    case MediaType.Photo.rawValue:
                        if let cached_image = ImageCache.fetch_image(for: element.media.id.uuidString) {
                            image_view(cached_image)
                        } else if let ui_image = ImageCache.set_image_and_return(for: element.media) {
                            image_view(ui_image)
                        }
                    case MediaType.Video.rawValue:
                        EmptyView()
                    case MediaType.GIF.rawValue:
                        AnimatedImage(data: element.media.image_data)
                            .resizable()
                            .customLoopCount(0)
                            .scaledToFit()
                    default:
                        EmptyView()
                    }
                }
                .onReceive(self.timer) { _ in
                    print(self.auto_slide_enabled)
                    guard self.auto_slide_enabled else { return } // Stops timer from changing index
                    
                    withAnimation {
                        self.current_media_index = (self.current_media_index + 1) % self.new_list.count
                    }
                }
            }
        }
        .onAppear {
            self.new_list = self.shuffle_list ? self.list.shuffled() : self.list
            
            if self.auto_slide_enabled {
                self.timer = Timer.publish(every: self.time_interval, on: .main, in: .common).autoconnect()
            }
        }
    }
}
