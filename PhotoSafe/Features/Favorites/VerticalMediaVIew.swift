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

struct VerticalMediaView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var slideShowViewModel: SlideShowViewModel

    var list: [SelectMediaEntity]

    @State private var current_media_index: Int = 0
    @State private var new_list: [SelectMediaEntity] = []
    @State private var timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    @State private var backgroundOpacity: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                LazyPagerView(
                    isDisplay: true,
                    direction: slideShowViewModel.slideShowDirection,
                    windowedList: self.$new_list,
                    windowListIndex: self.$current_media_index,
                    backgroundOpacity: self.$backgroundOpacity,
                    userTapped: .constant(false)
                )
                .overlay(alignment: .top) {
                    HStack {
                        Button {
                            self.dismiss()
                        } label: {
                            Image(systemName: "xmark.circle")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width:20,height:20)
                                .foregroundStyle(.red)
                        }

                        Spacer()

                        Button {
                            print("TODO")
                        } label: {
                            Image(systemName: "gearshape.circle.fill")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width:20,height:20)
                                .foregroundStyle(Color.c1_accent)
                        }
                    }
                    .overlay(alignment: .center, content: {
                        Text("\(current_media_index + 1) of \(new_list.count)")
                            .font(.system(size: 16, weight: .semibold,design: .rounded))
                            .foregroundStyle(.white)
                    })
                    .padding(.horizontal)
                    .padding([.top],10)
                }
                .onReceive(self.timer) { _ in
                    guard self.slideShowViewModel.autoPlayEnabled else { return }
                    // Check if current index is on video
                    // If it is disable timer until user gets off video
                    let element = self.new_list[self.current_media_index]
                    if element.media.type == MediaType.Video.rawValue { return }
                    
                    withAnimation {
                        self.current_media_index = (self.current_media_index + 1) % self.new_list.count
                    }
                }
                
            }
        }
        .onAppear {
            guard self.new_list.isEmpty else { return }
            
            self.new_list = self.slideShowViewModel.isShuffleEnabled ? self.list.shuffled() : self.list

            if self.slideShowViewModel.autoPlayEnabled {
                self.timer = Timer.publish(every: self.slideShowViewModel.timeInteval, on: .main, in: .common).autoconnect()
            }
        }
    }
}
