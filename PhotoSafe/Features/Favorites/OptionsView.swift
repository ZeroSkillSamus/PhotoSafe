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
    
    var body: some View {
        ZStack {
            Color.c1_secondary.ignoresSafeArea()
            VStack {
                VStack(spacing: 15){
                    Text("Options")
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
                        
                        Picker("SlideShow Direction Options", selection: self.$slideShowViewModel.slideShowDirection) {
                            ForEach(SlideShowType.allCases, id:\.self) { type in
                                Text(type.rawValue)
                                    .foregroundStyle(Color.c1_text)
                                    .opacity(0.75)
                            }
                        }
                        .menuIndicator(.hidden)
                    }

                    HStack {
                        Text("Set Time Interval")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                        
                        Spacer()
                        
                        Picker("TimeInterval", selection: self.$slideShowViewModel.timeInteval) {
                            ForEach(self.timer_options, id:\.self) { type in
                                Text("\(String(format: "%.0f", type)) seconds")
                                    .foregroundStyle(Color.c1_text)
                                    .opacity(0.75)
                            }
                        }
                        .menuIndicator(.hidden)
                    }
                    .opacity(self.slideShowViewModel.autoPlayEnabled ? 1 : 0)
                }
                
                Spacer()
                
                Button {
                    self.dismiss()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.slideShowViewModel.showSlideShow()
                    }
                    
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.c1_accent)
                        Text("Set Settings")
                            .font(.system(size: 15,weight: .semibold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    .frame(height: 50)
                }
                
            }
            .padding()
        }
        .presentationDetents([.medium, .fraction(0.45)])
    }
}
