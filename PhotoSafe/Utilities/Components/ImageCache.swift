//
//  ImageCache.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/19/25.
//

import Foundation
import SwiftUI

class ImageCache {
    private static let image_only_cache = NSCache<NSString, UIImage>()
    
    // Key will be the UUID
    static func set_image_and_return(for media_entity: MediaEntity) -> UIImage? {
        if let ui_image = media_entity.full_image {
            let key = media_entity.id.uuidString
            self.image_only_cache.setObject(ui_image, forKey: key as NSString)
            
            return ui_image
        }
        
        return media_entity.full_image
    }
    
    static func preloadImages(medias: [SelectMediaEntity]) {
        DispatchQueue.global(qos: .background).async {
            for media in medias {
                if media.media.type == MediaType.Photo.rawValue {
                    if self.image_only_cache.object(forKey: media.media.id.uuidString as NSString) == nil,
                       let ui_image = media.media.full_image {
                        self.image_only_cache.setObject(ui_image, forKey: media.media.id.uuidString as NSString)
                    }
                }
            }
        }
    }
    
    static func fetch_image(for key: String) -> UIImage? {
        if let cachedImage = self.image_only_cache.object(forKey: key as NSString) {
            return cachedImage
        }
        return nil
    }
}
