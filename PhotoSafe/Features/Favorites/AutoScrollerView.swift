//
//  VerticalMediaVIew.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/22/25.
//

import SwiftUI
import LazyPager
import SDWebImageSwiftUI

struct AutoScrollerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var slideShowViewModel: SlideShowViewModel
    
    @State private var timer: Timer?
    
    var orignalList: [SelectMediaEntity]
    @State private var newList: [SelectMediaEntity] = []
    @State private var currentIndex: Int = 0
    
    @State private var backgroundOpacity: CGFloat = 1.0
    @State private var showOptionsSheet: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                LazyPagerView(
                    isDisplay: true,
                    direction: slideShowViewModel.slideShowDirection,
                    windowedList: self.$newList,
                    windowListIndex: self.$currentIndex,
                    backgroundOpacity: self.$backgroundOpacity,
                    userTapped: .constant(false)
                ) {
                    advanceToNextItem()
                }
                .overlay(alignment: .top) {
                    HStack {
                        Button {
                            self.dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(Color.c1_text)
                        }
                        .padding(10)
                        .applyLiquidGlassIfSupported(shape: .circle, color: Color.c1_accent,isInteractive: true)
                        
                        Spacer()

                        Button {
                            self.showOptionsSheet.toggle()
//                            print("TODO")
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Color.c1_text)
                                .font(.system(size: 20, design: .rounded))
                                .padding(10)
                                .applyLiquidGlassIfSupported(color: Color.c1_accent,isInteractive: true)
                        }
                    }
                    .overlay(alignment: .center, content: {
                        Text("\(currentIndex + 1) of \(newList.count)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    })
                    .padding(.horizontal)
                    .padding([.top], 10)
                }
            }
        }
        .sheet(isPresented: self.$showOptionsSheet, content: {
            OptionsView(shouldDismiss: false,title: "Update Scroller Options")
        })
        .onAppear {
            self.onAppear()
        }
        .onChange(of: self.currentIndex) { _, _ in
            self.scheduleForCurrentItem()
        }
        .onDisappear {
            self.stopTimer()
        }
        .onChange(of: self.showOptionsSheet) { oldValue, newValue in
            // When sheet is open need to stop the timer
            if newValue { self.stopTimer() }
            if !newValue { self.onAppear() }
        }
    }
    
    private func onAppear() {
        if orignalList.isEmpty {
            self.dismiss()
            return
        }
        
        self.newList = self.slideShowViewModel.isShuffleEnabled ? self.orignalList.shuffled() : self.orignalList
        if self.slideShowViewModel.autoPlayEnabled { self.scheduleForCurrentItem() }
    }
    
    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    private func scheduleForCurrentItem() {
        timer?.invalidate()
        timer = nil

        guard slideShowViewModel.autoPlayEnabled,
              newList.indices.contains(currentIndex)
        else { return }

        let element = newList[currentIndex]
        guard element.type != MediaType.Video.rawValue else { return }

        timer = Timer.scheduledTimer(withTimeInterval: slideShowViewModel.timeInteval, repeats: false) { _ in
            Task { @MainActor in
                advanceToNextItem()
            }
        }
    }
    
    private func advanceToNextItem() {
        guard !newList.isEmpty else { return }
        
        withAnimation {
            currentIndex = (currentIndex + 1) % newList.count
        }
        
        scheduleForCurrentItem()
    }
}
