//
//  OptionsView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/23/25.
//

import SwiftUI

struct OptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let timer_options: [TimeInterval] = [2,3,5,10]
    
    @Binding var display_slide_show: Bool
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
                    
                    //if play_slides_auto {
                    Menu {
                        ForEach(self.timer_options,id: \.self) { time in
                            Button {
                                self.time_interval = time
                            } label: {
                                HStack {
                                    if time == time_interval {
                                        Image(systemName: "checkmark")
                                    }
                                    Text("\(time) Seconds")
                                }
                            }
                        }
                    } label: {
                        Text("Play Slides for \(time_interval) seconds")
                            .font(.system(size: 16,weight: .bold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    .opacity(self.play_slides_auto ? 1 : 0)
                    .frame(maxWidth: .infinity,alignment: .leading)
                }
                
                Spacer()
                
                Button {
                    self.dismiss()
                    print(self.display_slide_show)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.display_slide_show = true
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
        .presentationDetents([.medium, .fraction(0.35)])
    }
}
