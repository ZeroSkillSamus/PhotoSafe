//
//  URL+Thumbnail.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/2/25.
//

import SwiftUI
import AVKit

extension URL {
    func generateVideoThumbnail() -> Data? {
        let asset = AVAsset(url: self)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 10, preferredTimescale: 60), actualTime: nil)
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 1)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}
