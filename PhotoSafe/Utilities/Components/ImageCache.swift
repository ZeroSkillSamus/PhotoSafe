//
//  ImageCache.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/19/25.
//

import Foundation
import SwiftUI

class ImageCache {
    private static let image_only_cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        return cache
    }()

    // Calculates the actual memory footprint of a UIImage in bytes
    private static func cost(for image: UIImage) -> Int {
        image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
    }

    // Key will be the UUID
    static func setEncryptedImageAndReturn(
        for mediaEntity: MediaEntity,
        encryptionService: MediaEncryptionServiceProtocol = MediaEncryptionService.shared
    ) -> UIImage? {
        do {
            let decryptedData = try encryptionService.decrypt(mediaEntity.image_data)

            guard let uiImage = UIImage(data: decryptedData) else {
                return nil
            }

            let key = mediaEntity.id.uuidString
            self.image_only_cache.setObject(uiImage, forKey: key as NSString, cost: cost(for: uiImage))
            return uiImage
        } catch {
            return nil
        }
    }
    
    static func setEncryptedImageAndReturn(
        data: Data,
        key: String,
        encryptionService: MediaEncryptionServiceProtocol = MediaEncryptionService.shared
    ) -> UIImage? {
        do {
            let decryptedData = try encryptionService.decrypt(data)

            guard let uiImage = UIImage(data: decryptedData) else {
                return nil
            }
            
            self.image_only_cache.setObject(uiImage, forKey: key as NSString, cost: cost(for: uiImage))
            return uiImage
        } catch {
            return nil
        }
    }

    static func preloadImages(medias: [SelectMediaEntity]) {
        DispatchQueue.global(qos: .background).async {
            for media in medias {
                if media.type == MediaType.Photo.rawValue {
                    if self.image_only_cache.object(forKey: media.id.uuidString as NSString) == nil,
                       let ui_image = media.decryptedFullImage {
                        self.image_only_cache.setObject(ui_image, forKey: media.id.uuidString as NSString, cost: cost(for: ui_image))
                    }
                }
            }
        }
    }

    static func fetch_image(for key: String) -> UIImage? {
        return self.image_only_cache.object(forKey: key as NSString)
    }
}
