//
//  OptionsView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/23/25.
//

import SwiftUI
enum SlideShowType: String, CaseIterable {
    case vertical = "Vertical"
    case horizontal = "Horizontal"
}

struct OptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var slideShowViewModel: SlideShowViewModel
    
    let timer_options: [TimeInterval] = [2,3,5,10]
    var shouldDismiss: Bool = true
    var title: String = "Customize Scroller Options"
    
    var body: some View {
        ZStack {
            Color.c1_secondary.opacity(0.8).ignoresSafeArea()
            VStack {
                VStack(spacing: 15){
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(Color.c1_text)
                    
                    Toggle(isOn: self.$slideShowViewModel.isShuffleEnabled) {
                        Text("Shuffle")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    
                    Toggle(isOn: self.$slideShowViewModel.autoPlayEnabled) {
                        Text("Play Slides Auto")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    
                    HStack {
                        Text("Choose Swipe Direction")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(SlideShowType.allCases, id: \.self) { type in
                                Button {
                                    self.slideShowViewModel.slideShowDirection = type
                                } label: {
                                    Text(type.rawValue)
                                }
                            }
                        } label: {
                            Text(self.slideShowViewModel.slideShowDirection.rawValue)
                                .foregroundStyle(Color.c1_text)
                        }
                        .menuIndicator(.hidden)
//                        .padding(7)
//                        .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 10))
                    }

                    HStack {
                        Text("Set Time Interval")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(self.timer_options, id: \.self) { type in
                                Button {
                                    self.slideShowViewModel.timeInteval = type
                                } label: {
                                    Text("\(String(format: "%.0f", type)) seconds")
                                }
                            }
                        } label: {
                            Text("\(String(format: "%.0f", self.slideShowViewModel.timeInteval)) seconds")
                                .foregroundStyle(Color.c1_text)
                        }
                        .menuIndicator(.hidden)
//                        .padding(7)
//                        .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 10))
                    }
                    .disabled(self.slideShowViewModel.autoPlayEnabled ? false : true)
                    .opacity(self.slideShowViewModel.autoPlayEnabled ? 1 : 0.6)
                }
                
                //Spacer()
                
                Button {
                    self.dismiss()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.c1_accent)
                        Text("Start Slideshow")
                            .font(.system(size: 15,weight: .semibold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    .frame(height: 50)
                }
                
            }
            .padding(10)
        }
        .presentationDetents([.fraction(0.40)])
        .onDisappear {
            if !self.shouldDismiss { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.slideShowViewModel.showSlideShow()
            }
        }
        .presentationDragIndicator(.visible)
    }
}
