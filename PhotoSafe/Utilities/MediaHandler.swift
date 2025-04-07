//
//  ImageSaver.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/5/25.
//

import SwiftUI
import Photos

// Handles Saving & Deleting to Users photo library
class MediaHandler: NSObject {
    // Convert to PHAsset
    static func fetchAsset(with identifier: String) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return fetchResult.firstObject
    }
    
    // Function to delete multiple assets
    static func deleteAssets(_ assets: [PHAsset]) {
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
    
    func save_video_to_user_library(vid_path: String) {
        UISaveVideoAtPathToSavedPhotosAlbum(vid_path, self, #selector(save_completed), nil)
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
        print("Save Finished!")
    }
    
}
