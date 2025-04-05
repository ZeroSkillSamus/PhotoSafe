//
//  FullCoverSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI
import AVKit
import SDWebImageSwiftUI

struct PlayerTest: View {
    @State private var controller: AVPlayerViewController = AVPlayerViewController()
    let url: URL
    @State private var is_controls_active: Bool = false
    @State private var player_value: Float = 0
    @State private var is_video_playing: Bool = true
    
    func middle_header() -> some View {
        return (
            HStack(spacing:50) {
                Button {
                    let curr_time = (self.controller.player?.currentTime().seconds ?? 0)
                    let new_time = curr_time - 15 <= 0 ? 0 : curr_time - 15
                    
                    self.controller.player?.seek(to: CMTime(seconds: new_time, preferredTimescale: 800))
                } label: {
                    //goforward.15
                    Image(systemName: "gobackward.15")
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
                    
                    let new_time = curr_time + 15 >= duration ? duration : curr_time + 15
                    self.controller.player?.seek(to: CMTime(seconds: new_time, preferredTimescale: 800))
                } label: {
                    Image(systemName: "goforward.15")
                        .foregroundStyle(.blue)
                        .font(.system(size: 30))
                }
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .background(Color.black.opacity(0.35))
            .onTapGesture {
                self.is_controls_active = false
            }
        )
    }
    
    var body: some View {
        ZStack {
            CustomVideoPlayer(url: self.url,controller: self.$controller)
                .onAppear {
                    self.controller.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 800), queue: .main, using: { time in
                        let duration = self.controller.player?.currentItem?.duration.seconds ?? 1.0
                        self.player_value = Float(time.seconds / duration) //For Slider
                    })
                    self.controller.player?.play()
                }
                
                .onTapGesture {
                    self.is_controls_active.toggle()
                }
                .onDisappear {
                    self.controller.player?.pause()
                }
                .edgesIgnoringSafeArea(.all)
            
            
            if self.is_controls_active {
                VStack(spacing: 0) {
                    middle_header()
                    
                    NewCustomProgressBar(
                        value: self.player_value,
                        isPlaying: self.is_video_playing,
                        player_controller: self.$controller
                    )
                    .background(Color.black.opacity(0.35))
                }
                
                .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .bottom)
            }
        }
        .ignoresSafeArea()
        
        
        
    }
}

struct FullCoverSheet: View {
    @Environment(\.dismiss) var dismiss

    var select_media: SelectMediaEntity
    var list: [SelectMediaEntity]
    
    @State private var current_media_index: Int = 0
    @State private var curr_media: SelectMediaEntity?
    @State var player_controller: AVPlayerViewController = AVPlayerViewController()
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "x.circle")
                            .font(.title3)
                    }
                    .foregroundStyle(.red)
                    
                    Spacer()
                    
                    Button {
                        print("Edit")
                    } label: {
                        Text("Edit")
                    }
                    .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: 60,alignment: .topLeading)
                .padding(5)
                .overlay(alignment: .top) {
                    Text("\(current_media_index + 1) of \(list.count)")
                        .font(.title3)
                        .padding(5)
                        .foregroundStyle(.primary)
                }
 
                TabView(selection: $current_media_index) {
                    ForEach(0..<list.count,id:\.self) { index in
                        VStack {
                            switch list[index].media.type {
                            case MediaType.Photo.rawValue:
                                if let image = list[index].media.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                }
                            case MediaType.Video.rawValue:
                                if let video_path = list[index].media.video_path, let url = URL(string: video_path) {
                                    PlayerTest(url: url)
                                }
                            case MediaType.GIF.rawValue:
                                AnimatedImage(data: list[index].media.image_data)
                                    .resizable()
                                    .customLoopCount(0)
                                    .scaledToFit()
                                
                            default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(5)
        }
        .onAppear {
            self.current_media_index = self.list.firstIndex(of: self.select_media) ?? 0
        }
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
    }
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let url: URL
    @Binding var controller: AVPlayerViewController
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        //let controller = AVPlayerViewController()
        self.controller.player = AVPlayer(url: url)
        self.controller.showsPlaybackControls = false
        self.controller.view.isUserInteractionEnabled = false
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct NewCustomProgressBar: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        return NewCustomProgressBar.Coordinator(parent1: self)
    }
    
    var value: Float
    var isPlaying: Bool
    @Binding var player_controller: AVPlayerViewController

    func makeUIView(context: Context) -> some UISlider {
        let slider = UISlider()
        slider.minimumTrackTintColor = UIColor(.blue)
        slider.maximumTrackTintColor = UIColor(.green)

        // Create a custom thumb image with the desired color
        if let thumbImage = UIImage(systemName: "circle.fill") {
            let coloredThumbImage = thumbImage.withTintColor(UIColor(.red), renderingMode: .alwaysOriginal)
            slider.setThumbImage(coloredThumbImage, for: .normal)
            slider.setThumbImage(coloredThumbImage, for: .highlighted)
        }
        
        slider.addTarget(context.coordinator, action: #selector(context.coordinator.changed(slider:)), for: .valueChanged)
        return slider
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.value = value
    }
    
    class Coordinator: NSObject {
        var parent: NewCustomProgressBar
        
        init(parent1: NewCustomProgressBar) {
            self.parent = parent1
        }
        
        @objc func changed(slider: UISlider) {
            if slider.isTracking {
                parent.player_controller.player?.pause()
                //let sec = Double(slider.value * Float(parent.player.currentItem?.duration.seconds ?? 0))
                let sec = Double(slider.value * Float(parent.player_controller.player?.currentItem?.duration.seconds ?? 0))
                //print("Hi")
                parent.player_controller.player?.seek(to: CMTime(seconds:sec,preferredTimescale: 800))
            } else {
                let sec = Double(slider.value * Float(parent.player_controller.player?.currentItem?.duration.seconds ?? 0))
                
                parent.player_controller.player?.seek(to: CMTime(seconds:sec,preferredTimescale: 800))
                
                if self.parent.isPlaying {
                    parent.player_controller.player?.play()
                }
            }
        }
        
    }
}
