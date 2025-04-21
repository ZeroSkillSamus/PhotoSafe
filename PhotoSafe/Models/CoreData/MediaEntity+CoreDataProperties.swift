//
//  MediaEntity+CoreDataProperties.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/30/25.
//
//

import SwiftUI
import CoreData

@objc(MediaEntity)
public class MediaEntity: NSManagedObject {

}

extension MediaEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaEntity> {
        return NSFetchRequest<MediaEntity>(entityName: "MediaEntity")
    }
    
    var full_image: UIImage? {
        UIImage(data: image_data)
    }
    
    var thumbnail_image: UIImage? {
        UIImage(data: thumbnail)
    }
    
    @NSManaged public var image_data: Data
    @NSManaged public var date_added: Date
    @NSManaged public var type: String
    @NSManaged public var video_path: String?
    @NSManaged public var album: AlbumEntity
    @NSManaged public var is_favorited: Bool
    @NSManaged public var thumbnail: Data
    @NSManaged public var id: UUID
}

extension MediaEntity : Identifiable {

}

extension UIImage {
    func thumbnail(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        let imageRenderer = UIGraphicsImageRenderer(size: size)
        return imageRenderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
