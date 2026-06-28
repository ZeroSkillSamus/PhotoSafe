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
            let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 1)
        } catch {
            return nil
        }
    }
    
//    func generateMovpkgThumbnail() async -> Data? {
//          let asset = AVURLAsset(url: self)
//
//          do {
//              let tracks = try await asset.loadTracks(withMediaType: .video)
//              guard let videoTrack = tracks.first else { return nil }
//      
//              let reader = try AVAssetReader(asset: asset)
//              let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [
//                  kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//              ])
//              reader.add(output)
//              reader.startReading()
//      
//              guard let sampleBuffer = output.copyNextSampleBuffer(),
//                    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
//
//              let ciImage = CIImage(cvPixelBuffer: imageBuffer)
//              let context = CIContext()
//              guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
//
//              return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.5)
	//          } catch {
	//              return nil
	//          }
//      }
}
