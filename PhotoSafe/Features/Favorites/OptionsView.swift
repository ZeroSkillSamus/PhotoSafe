//
//  OptionsView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/23/25.
//

import SwiftUI
enum SlideShowType: String, CaseIterable {
    case Vertical = "Vertical"
    case Horizontal = "Horizontal"
}

struct OptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var slide_show_type: SlideShowType = .Vertical
    
    let timer_options: [TimeInterval] = [2,3,5,10]
    
    @Binding var display_vertical_slide: Bool
    @Binding var display_horizontal_slide: Bool
    @Binding var toggle_shuffle: Bool
    @Binding var play_slides_auto: Bool
    @Binding var time_interval: TimeInterval
    
    var body: some View {
        ZStack {
            Color.c1_secondary.ignoresSafeArea()
            VStack {
                VStack(spacing: 15){
                    Text("Options")
                        .font(.title2.bold())
                        .foregroundStyle(Color.c1_text)
                    
                    Toggle(isOn: self.$toggle_shuffle) {
                        Text("Shuffle")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    
                    Toggle(isOn: self.$play_slides_auto) {
                        Text("Play Slides Auto")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    
                    HStack {
                        Text("Choose Swipe Direction")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                        
                        Spacer()
                        
                        Picker("SlideShow Direction Options", selection: self.$slide_show_type) {
                            ForEach(SlideShowType.allCases, id:\.self) { type in
                                Text(type.rawValue)
                            }
                        }
                        .menuIndicator(.hidden)
                    }

                    HStack {
                        Text("Set Time Interval")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                        
                        Spacer()
                        
                        Picker("TimeInterval", selection: self.$time_interval) {
                            ForEach(self.timer_options, id:\.self) { type in
                                Text("\(String(format: "%.0f", type)) seconds")
                            }
                        }
                        .menuIndicator(.hidden)
                    }
                    .opacity(self.play_slides_auto ? 1 : 0)
                }
                
                Spacer()
                
                Button {
                    self.dismiss()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        switch self.slide_show_type {
                        case .Vertical:
                            display_vertical_slide = true
                        case .Horizontal:
                            display_horizontal_slide = true
                        }
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
