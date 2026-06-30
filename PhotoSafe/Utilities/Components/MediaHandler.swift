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
final class MediaHandler {
    private let userDefaults: UserDefaults
    
    var choosenExportOption: DestinationChoices {
        let rawVal = userDefaults.string(forKey: StorageKeys.exportDestination) ?? DestinationChoices.photoslibrary.rawValue
        return DestinationChoices(rawValue: rawVal) ?? DestinationChoices.photoslibrary
    }
    
    var customAlbumName: String? {
        userDefaults.string(forKey: StorageKeys.exportAlbumName)
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// Convert the identifier to PHAsset
    func fetchAsset(with identifier: String) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return fetchResult.firstObject
    }

    /// Function to delete multiple assets
    func deleteAssets(_ assets: [PHAsset]) {
        if assets.isEmpty {
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
            if !success, error != nil {}
        }
    }

    func savePhotoToUserLibrary(image: UIImage, completion: @escaping (ToastItem) -> Void) {
            PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(ToastItem(message: "Need photo library access to export photo", status: .failure))
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                // Request to create the photo asset
                let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                
                if let albumName = self.customAlbumName, !albumName.isEmpty, self.choosenExportOption == .chosenAlbum {
                    guard let assetPlaceholder = assetRequest.placeholderForCreatedAsset else {
                        return
                    }
                    
                    let album = self.fetchOrCreateAlbumChangeRequest(named: albumName)
                    album?.addAssets([assetPlaceholder] as NSArray)
                }
                
            }, completionHandler: { success, error in
                if success {
                    completion(ToastItem(message: "Image Saved", status: .success))
                } else {
                    completion(ToastItem(message: "\(error?.localizedDescription ?? "Unknown error")", status: .failure))
                }
            })
        }
    }

    func saveVideoToUserLibrary(at path: String, completion: @escaping (ToastItem) -> Void) {
        guard let urlObject = URL(string: path) else {
            completion(ToastItem(message: "Error: Could not parse string as a URL", status: .failure))
            return
        }

        let trueFilePath = urlObject.path
        let managedAccess = urlObject.startAccessingSecurityScopedResource()

        guard FileManager.default.fileExists(atPath: trueFilePath) else {
            completion(ToastItem(message: "Error: Video file doesn't exist at path", status: .failure))
            return
        }

            PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(ToastItem(message: "Need photo library access to export video", status: .failure))
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let url = URL(fileURLWithPath: trueFilePath)
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                
                if let albumName = self.customAlbumName, !albumName.isEmpty, self.choosenExportOption == .chosenAlbum {
                    guard let assetPlaceholder = assetRequest?.placeholderForCreatedAsset else {
                        return
                    }
                    
                    let album = self.fetchOrCreateAlbumChangeRequest(named: albumName)
                    album?.addAssets([assetPlaceholder] as NSArray)
                }
            }) { success, error in
                if managedAccess { urlObject.stopAccessingSecurityScopedResource() }
                DispatchQueue.main.async {
                    if success {
                        completion(ToastItem(message: "Video Saved", status: .success))
                    } else {
                        completion(ToastItem(message: "\(error?.localizedDescription ?? "Unknown error")", status: .failure))
                    }
                }
            }
        }
    }

    func saveGifToUserLibrary(data: Data, completion: @escaping (ToastItem) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            
            let assetRequest = PHAssetCreationRequest.forAsset()
            assetRequest.addResource(with: .photo, data: data, options: nil)
            
            if let albumName = self.customAlbumName, !albumName.isEmpty, self.choosenExportOption == .chosenAlbum {
                guard let assetPlaceholder = assetRequest.placeholderForCreatedAsset else {
                    return
                }
                
                let album = self.fetchOrCreateAlbumChangeRequest(named: albumName)
                album?.addAssets([assetPlaceholder] as NSArray)
            }
        }) { (success, error) in
            if let error = error {
                completion(ToastItem(message: error.localizedDescription, status: .failure))
            } else {
                completion(ToastItem(message: "Gif Saved", status: .success))
            }
        }
    }
    
    func fetchAlbum(named albumName: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)

        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: fetchOptions
        ).firstObject
    }
    
    func fetchOrCreateAlbumChangeRequest(named albumName: String) -> PHAssetCollectionChangeRequest? {
        if let existingAlbum = fetchAlbum(named: albumName) {
            return PHAssetCollectionChangeRequest(for: existingAlbum)
        } else {
            return PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
        }
    }
}
