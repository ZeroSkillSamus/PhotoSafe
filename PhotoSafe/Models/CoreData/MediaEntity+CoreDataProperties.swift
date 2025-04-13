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
    
    var image: UIImage? {
        UIImage(data: image_data)
    }
    
    @NSManaged public var image_data: Data
    @NSManaged public var date_added: Date
    @NSManaged public var type: String
    @NSManaged public var video_path: String?
    @NSManaged public var album: AlbumEntity
    @NSManaged public var is_favorited: Bool
}

extension MediaEntity : Identifiable {

}
