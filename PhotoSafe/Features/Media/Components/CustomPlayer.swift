//
//  CustomPlayer.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/2/25.
//

import SwiftUI
import AVKit

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let url: URL
    @Binding var controller: AVPlayerViewController
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        //let controller = AVPlayerViewController()
        self.controller.player = AVPlayer(url: url)
        self.controller.showsPlaybackControls = false
        self.controller.view.isUserInteractionEnabled = false
        self.controller.videoGravity = .resizeAspect
        
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
        slider.minimumTrackTintColor = UIColor(.secondary)
        slider.maximumTrackTintColor = UIColor(.primary)

        // Create a custom thumb image with the desired color
        if let thumbImage = UIImage(systemName: "circle.fill") {
            let coloredThumbImage = thumbImage.withTintColor(UIColor(.white ), renderingMode: .alwaysOriginal)
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
