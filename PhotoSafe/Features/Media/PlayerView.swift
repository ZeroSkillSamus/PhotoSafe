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
    @Environment(\.dismiss) var dismiss
    
    @State private var controller: AVPlayerViewController = AVPlayerViewController()
    @State private var is_controls_active: Bool = false
    @State private var player_value: Float = 0
    @State private var is_video_playing: Bool = true
    @State private var url: URL?
    @State private var timeObserverToken: Any?
    
    var media: SelectMediaEntity
    var showDismiss: Bool = false
    var handleOnVideoEnd: (() -> Void)?
    
    func addTimeObserver() {
        guard timeObserverToken == nil else { return }

        timeObserverToken = controller.player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 800),
            queue: .main
        ) { time in
            guard let duration = controller.player?.currentItem?.duration.seconds,
                  duration.isFinite,
                  duration > 0,
                  time.seconds.isFinite else {
                player_value = 0
                return
            }

            player_value = Float(time.seconds / duration)
        }
    }
    
    func removeTimeObserver() {
        if let timeObserverToken {
            controller.player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    func covertSecondsToReadableFormat(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds.isNaN ? 0 : seconds)
        let hours = (totalSeconds / 3600)
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        return hours == 0
                ? String(format: "%02d:%02d", minutes, seconds)
                : String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    var current_timestamp: String {
        self.covertSecondsToReadableFormat(self.controller.player?.currentTime().seconds ?? 0.0)
    }
    
    var duration_timestamp: String {
        self.covertSecondsToReadableFormat(self.controller.player?.currentItem?.duration.seconds ?? 1.0)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let url {
                CustomVideoPlayer(url: url, controller: self.$controller)
                    .onAppear {
                        self.addTimeObserver()
                        self.controller.player?.play()
                    }
                    .onDisappear {
                        self.controller.player?.pause()
                        self.removeTimeObserver()
                        
                        // Remove temp file
//                        if let url {
                        try? MediaFileVaultService.shared.deleteTemporaryPlaybackFile(at: url)
                        self.url = nil
//                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(
                        for: .AVPlayerItemDidPlayToEndTime,
                        object: controller.player?.currentItem
                    )) { _ in
                        if let handleOnVideoEnd {
                            handleOnVideoEnd()
                        }
                    }
                
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            self.is_controls_active.toggle()
                        }
                    }

                if self.is_controls_active {
                    VStack(spacing: 0) {
                        if showDismiss {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .padding(9)
                                    .foregroundStyle(Color.c1_text)
                            }
                            .applyLiquidGlassIfSupported(shape: .circle,color: Color.c1_accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.35))
                            .padding(.top,9)
                        }
                        playbackControls()
                        
                        HStack {
                            Text(current_timestamp)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .bold()
                            
                            NewCustomProgressBar(
                                value: self.player_value,
                                isPlaying: self.is_video_playing,
                                player_controller: self.$controller
                            )
            
                            Text(self.duration_timestamp)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .bold()
                        }
                        .padding(.horizontal,12)
                        .padding(.bottom,9)
                        .background(Color.black.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .bottom)
                    .background(Color.black.opacity(0.35))
                }
            } else {
                ProgressView()
            }
        }
        .task(id: media.id) {
            do {
                guard let lastPathComponent = media.videoPath else {
                    self.url = nil
                    return
                }
                let encryptedURL = try MediaStoragePaths.encryptedVideoURL(
                    from: lastPathComponent
                )
                let playbackURL = try await Task.detached(priority: .userInitiated) {
                    try MediaFileVaultService.shared.decryptVideoFileToTemporaryURL(
                        from: encryptedURL,
                        id: media.id
                    )
                }.value
                
                self.url = playbackURL
            } catch {
                self.url = nil
            }
            
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    func playbackControls() -> some View {
        return (
            HStack(spacing:50) {
                Button {
                    let currTime = (self.controller.player?.currentTime().seconds ?? 0)
                    let newTime = currTime - 10 <= 0 ? 0 : currTime - 10
                    
                    self.controller.player?.seek(to: CMTime(seconds: newTime, preferredTimescale: 800))
                } label: {
                    Image(systemName: "gobackward.10")
                        .foregroundStyle(Color.c1_accent)
                        .font(.system(size: 30))
                }
                
                Button {
                    withAnimation {
                        self.is_video_playing ? self.controller.player?.pause() : self.controller.player?.play()
                        self.is_video_playing.toggle()
                    }
                } label: {
                    Image(systemName: self.is_video_playing ? "pause.circle" : "play.circle")
                        .foregroundStyle(Color.c1_accent)
                        .font(.system(size: 50))
                }
                
                Button {
                    let curr_time = (self.controller.player?.currentTime().seconds ?? 0)
                    let duration = self.controller.player?.currentItem?.duration.seconds ?? 0
                    
                    let new_time = curr_time + 10 >= duration ? duration : curr_time + 10
                    self.controller.player?.seek(to: CMTime(seconds: new_time, preferredTimescale: 800))
                } label: {
                    Image(systemName: "goforward.10")
                        .foregroundStyle(Color.c1_accent)
                        .font(.system(size: 30))
                }
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .background(Color.black.opacity(0.35))
            .onTapGesture {
                withAnimation {
                    self.is_controls_active = false
                }
                
            }
        )
    }
}
