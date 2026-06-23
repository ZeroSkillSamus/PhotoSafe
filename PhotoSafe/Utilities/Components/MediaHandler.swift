//
//  ImageSaver.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/5/25.
//

import SwiftUI
import Photos
import UIKit

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

    static func savePhotoToUserLibrary(image: UIImage, completion: @escaping (ToastItem) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access denied")
                completion(ToastItem(message: "Need photo library access to export photo", status: .failure))
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                // Request to create the photo asset
                PHAssetChangeRequest.creationRequestForAsset(from: image)
                
            }, completionHandler: { success, error in
                if success {
                    print("Successfully saved the photo!")
                    completion(ToastItem(message: "Image Saved", status: .success))
                } else {
                    print("Error saving photo: \(error?.localizedDescription ?? "Unknown error")")
                    completion(ToastItem(message: "\(error?.localizedDescription ?? "Unknown error")", status: .failure))
                }
            })
        }
    }

    static func saveVideoToUserLibrary(at path: String, completion: @escaping (ToastItem) -> Void) {
        guard let urlObject = URL(string: path) else {
            print("Error: Could not parse string as a URL")
            completion(ToastItem(message: "Error: Could not parse string as a URL", status: .failure))
            return
        }

        let trueFilePath = urlObject.path
        let managedAccess = urlObject.startAccessingSecurityScopedResource()

        guard FileManager.default.fileExists(atPath: trueFilePath) else {
            print(urlObject.path)
            print("Error: Video file doesn't exist at path")
            completion(ToastItem(message: "Error: Video file doesn't exist at path", status: .failure))
            return
        }

        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access denied")
                completion(ToastItem(message: "Need photo library access to export video", status: .failure))
                return
            }

            PHPhotoLibrary.shared().performChanges({
                        let url = URL(fileURLWithPath: trueFilePath)
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    }) { success, error in
                        if managedAccess {
                            urlObject.stopAccessingSecurityScopedResource()
                        }
                    DispatchQueue.main.async {
                        if success {
                            print("Video saved to Photos library")
                            completion(ToastItem(message: "Video Saved", status: .success))
                        } else {
                            print("Error saving video: \(error?.localizedDescription ?? "Unknown error")")
                            completion(ToastItem(message: "\(error?.localizedDescription ?? "Unknown error")", status: .failure))
                            if let error = error as NSError? {
                                print("Full error details: \(error)")
                            }
                        }
                    }
                }
        }
    }

    static func saveGifToUserLibrary(data: Data, completion: @escaping (ToastItem) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
        }) { (success, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(ToastItem(message: error.localizedDescription, status: .failure))
            } else {
                print("GIF has saved")
                completion(ToastItem(message: "Gif Saved", status: .success))
            }
        }
    }
}
