//
//  ImageSaver.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/5/25.
//

import SwiftUI
import Photos

/// Class that handles saving & deleting from the user photo library.
///
///
/// - Tag: MediaHandler
/// - Author: Abraham Mitchell
/// - Version: 1.0
/// - Copyright: Your Company
class MediaHandler: NSObject {
    
    /// Convert the identifier to PHAsset
    static func fetchAsset(with identifier: String) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return fetchResult.firstObject
    }
    
    /// Function to delete multiple assets
    static func deleteAssets(_ assets: [PHAsset]) {
        if assets.isEmpty { return }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
            if !success, let error = error {
                print("Error deleting assets: \(error.localizedDescription)")
            }
        }
    }
    
    func save_photo_to_user_library(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(save_completed), nil)
    }
    
    func save_video_to_user_library(at path: String) {
        let fileManager = FileManager.default
        let isReadable = fileManager.isReadableFile(atPath: path)
        print("Is file readable? \(isReadable)")
    
        let originalURL = URL(fileURLWithPath: path)
        
        guard FileManager.default.fileExists(atPath: originalURL.path) else {
            print(originalURL.path)
            print("Error: Video file doesn't exist at path")
            return
        }
        
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access denied")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                        let url = URL(fileURLWithPath: path)
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("Video saved to Photos library")
                        } else {
                            print("Error saving video: \(error?.localizedDescription ?? "Unknown error")")
                            // Additional error inspection:
                            if let error = error as NSError? {
                                print("Full error details: \(error)")
                            }
                        }
                    }
                }
        }
    }
    
    func save_gif_to_user_library(data: Data) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
        }) { (success, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("GIF has saved")
            }
        }
    }
    
    @objc func save_completed(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving Media: \(error.localizedDescription)")
            // Show error to user
        } else {
            print("Media Saved Successfully!")
            // Show success message
        }
    }
    
}
