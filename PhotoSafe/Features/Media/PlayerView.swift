//
//  PlayerView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/2/25.
//

import SwiftUI
import AVKit

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct PlayerView: View {
    @State private var controller: AVPlayerViewController = AVPlayerViewController()
    @State private var is_controls_active: Bool = false
    @State private var player_value: Float = 0
    @State private var is_video_playing: Bool = true

    @Binding var did_user_tap: Bool
    var curr_orientation: UIDeviceOrientation
    var prev_orientation: UIDeviceOrientation
  
    let url: URL
    
    func add_time_observer() {
        self.controller.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 800), queue: .main, using: { time in
            let duration = self.controller.player?.currentItem?.duration.seconds ?? 1.0
            self.player_value = Float(time.seconds / duration) //For Slider
        })
    }
    
    func convert_seconds(_ seconds: Double) -> String {
        let time_as_int = Int(seconds.isNaN ? 0 : seconds)
        let hours = (time_as_int / 3600)
        let minutes = (time_as_int % 3600) / 60
        let seconds = (time_as_int % 3600) % 60
        
        let customFormatter = NumberFormatter()
        customFormatter.maximumIntegerDigits = 2
        customFormatter.minimumIntegerDigits = 2

        let newSec = customFormatter.string(from: seconds as NSNumber) ?? "00"
        let newMin = customFormatter.string(from: minutes as NSNumber) ?? "00"
        return hours == 0 ? "\(newMin):\(newSec)" : "\(hours):\(newMin):\(newSec)"
    }

    var current_timestamp: String {
        self.convert_seconds(self.controller.player?.currentTime().seconds ?? 0.0)
    }
    
    var duration_timestamp: String {
        self.convert_seconds(self.controller.player?.currentItem?.duration.seconds ?? 1.0)
    }
    
    var bottom_padding_length: CGFloat {
        //Flat & Portrait
        if self.curr_orientation.isPortrait || (self.prev_orientation.isPortrait && self.curr_orientation.isFlat) {
            return 40
        }
        
        // Flat & Landscape
        if self.curr_orientation.isLandscape || (self.prev_orientation.isLandscape && self.curr_orientation.isFlat) {
            return 5
        }
        
        return 40 // curr_orientation is Flat
    }
    
    var body: some View {
        ZStack {
            CustomVideoPlayer(url: self.url,controller: self.$controller)
                .onAppear {
                    self.add_time_observer()
                    self.controller.player?.play()
                }
                .onTapGesture {
                    withAnimation {
                        self.is_controls_active.toggle()
                        self.did_user_tap.toggle()
                    }
                }
                .onDisappear {
                    self.controller.player?.pause()
                }
                
            
            if self.is_controls_active {
                VStack(spacing: 0) {
                    playback_controls()
                    
                    HStack {
                        Text(current_timestamp)
                            .font(.caption)
                            .bold()
                        
                        NewCustomProgressBar(
                            value: self.player_value,
                            isPlaying: self.is_video_playing,
                            player_controller: self.$controller
                        )
        
                        Text(self.duration_timestamp)
                            .font(.caption)
                            .bold()
                            
                    }
                    .padding(.horizontal)
                    .padding(.bottom,bottom_padding_length)
                    .background(Color.black.opacity(0.35))
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .bottom)
                .background(Color.black.opacity(0.35))
            }
        }

    }
    
    func playback_controls() -> some View {
        return (
            HStack(spacing:50) {
                Button {
                    let curr_time = (self.controller.player?.currentTime().seconds ?? 0)
                    let new_time = curr_time - 10 <= 0 ? 0 : curr_time - 10
                    
                    self.controller.player?.seek(to: CMTime(seconds: new_time, preferredTimescale: 800))
                } label: {
                    //goforward.15
                    Image(systemName: "gobackward.10")
                        .foregroundStyle(.blue)
                        .font(.system(size: 30))
                }
                
                Button {
                    withAnimation {
                        self.is_video_playing ? self.controller.player?.pause() : self.controller.player?.play()
                        self.is_video_playing.toggle()
                    }
                } label: {
                    Image(systemName: self.is_video_playing ? "pause.circle" : "play.circle")
                        .foregroundStyle(.blue)
                        .font(.system(size: 50))
                }
                
                Button {
                    let curr_time = (self.controller.player?.currentTime().seconds ?? 0)
                    let duration = self.controller.player?.currentItem?.duration.seconds ?? 0
                    
                    let new_time = curr_time + 10 >= duration ? duration : curr_time + 10
                    self.controller.player?.seek(to: CMTime(seconds: new_time, preferredTimescale: 800))
                } label: {
                    Image(systemName: "goforward.10")
                        .foregroundStyle(.blue)
                        .font(.system(size: 30))
                }
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .background(Color.black.opacity(0.35))
            .onTapGesture {
                withAnimation {
                    self.is_controls_active = false
                    self.did_user_tap.toggle()
                }
                
            }
        )
    }
}
