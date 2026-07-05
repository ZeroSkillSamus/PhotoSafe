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
    var title: String = "Playback Setup"
    
    var body: some View {
        ZStack {
            Color.c1_secondary.opacity(0.8).ignoresSafeArea()
            VStack {
                Text(title)
                    .font(.system(size: 23,weight: .bold, design: .rounded))
                    .foregroundStyle(Color.c1_text)
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .padding(13)
                
                VStack(spacing: 15){
                    
                    
                    Toggle(isOn: self.$slideShowViewModel.isShuffleEnabled) {
                        Text("Shuffle")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.c1_secondary))
                    
                    Toggle(isOn: self.$slideShowViewModel.autoPlayEnabled) {
                        Text("Play Slides Auto")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.c1_secondary))
                    HStack {
                        Text("Choose Swipe Direction")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                        
                        Spacer()
                        
//                        Picker("", selection: self.$slideShowViewModel.slideShowDirection) {
//                            ForEach(SlideShowType.allCases, id: \.self) { type in
//                                Text(type.rawValue)
//                            }
//                        }
//                        .pickerStyle(.menu)
//                        .menuIndicator(.hidden)
//                        .tint(Color.c1_text)
//                        .padding(.horizontal, 3)
//                        .padding(.vertical, 2)
//                        .background(
//                            RoundedRectangle(cornerRadius: 10)
//                                .fill(Color.c1_primary.opacity(0.12))
//                        )
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
                        .padding(7)
                        .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 10))
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.c1_secondary))
                    
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
                        .padding(7)
                        .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 10))
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.c1_secondary))
                    .disabled(self.slideShowViewModel.autoPlayEnabled ? false : true)
                    .opacity(self.slideShowViewModel.autoPlayEnabled ? 1 : 0)
                    
                }
                .padding(.horizontal, 15)
                //Spacer()
                
                Button {
                    self.dismiss()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.slideShowViewModel.showSlideShow()
                    }
                } label: {
                    Text("Start Slideshow")
                        .font(.system(size: 18,weight: .bold,design: .rounded))
                        .foregroundStyle(Color.c1_text)
                        .padding(17)
                        .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 15), color: Color.c1_accent, isInteractive: true)
                }
                .padding(.horizontal, 12)
            }
            .padding(8)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
