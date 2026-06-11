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
                
                LazyPagerView(
                    direction: slideShowViewModel.slideShowDirection,
                    windowedList: self.$new_list,
                    windowListIndex: self.$current_media_index,
                    backgroundOpacity: self.$backgroundOpacity,
                    userTapped: .constant(false)
                )
                    .onReceive(self.timer) { _ in
                        guard self.slideShowViewModel.autoPlayEnabled else { return } // Stops timer from changing index
                        
                        withAnimation {
                            self.current_media_index = (self.current_media_index + 1) % self.new_list.count
                        }
                    }
            }
        }
        .onAppear {
            self.new_list = self.slideShowViewModel.isShuffleEnabled ? self.list.shuffled() : self.list
            
            if self.slideShowViewModel.autoPlayEnabled {
                self.timer = Timer.publish(every: self.slideShowViewModel.timeInteval, on: .main, in: .common).autoconnect()
            }
        }
    }
}
