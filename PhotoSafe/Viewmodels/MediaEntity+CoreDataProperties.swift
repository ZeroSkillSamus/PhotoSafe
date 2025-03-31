//
//  MediaEntity+CoreDataProperties.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/30/25.
//
//

import Foundation
import CoreData


extension MediaEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaEntity> {
        return NSFetchRequest<MediaEntity>(entityName: "MediaEntity")
    }

    @NSManaged public var image_data: Data?
    @NSManaged public var date_added: Date?
    @NSManaged public var type: String?
    @NSManaged public var video_path: String?
    @NSManaged public var album: AlbumEntity?

}

extension MediaEntity : Identifiable {

}
