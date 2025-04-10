//
//  AlbumEntity+CoreDataProperties.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/30/25.
//
//

import Foundation
import CoreData

@objc(AlbumEntity)
public class AlbumEntity: NSManagedObject {

}

extension AlbumEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AlbumEntity> {
        return NSFetchRequest<AlbumEntity>(entityName: "AlbumEntity")
    }
    
    @nonobjc public class func deleteRequest() -> NSBatchDeleteRequest {
        return NSBatchDeleteRequest(fetchRequest: self.fetchRequest())
    }

    var is_locked: Bool {
        return password.isEmpty ? false : true
    }
    
    var fetch_medias_as_list: [MediaEntity]? {
        if let list = media?.allObjects as? [MediaEntity] {
            return list.sorted(by: { a, b in
                a.date_added < b.date_added
            })
        }
        return nil
    }
    
    var fetch_first_image: Data? {
        if let first = self.fetch_medias_as_list?.first {
            return first.image_data
        }
        return nil
    }

    @NSManaged public var image: Data?
    @NSManaged public var name: String
    @NSManaged public var password: String
    @NSManaged public var date_added: Date
    @NSManaged public var media: NSSet?

    
}

// MARK: Generated accessors for media
extension AlbumEntity {

    @objc(addMediaObject:)
    @NSManaged public func addToMedia(_ value: MediaEntity)

    @objc(removeMediaObject:)
    @NSManaged public func removeFromMedia(_ value: MediaEntity)

    @objc(addMedia:)
    @NSManaged public func addToMedia(_ values: NSSet)

    @objc(removeMedia:)
    @NSManaged public func removeFromMedia(_ values: NSSet)

}

extension AlbumEntity : Identifiable {

}
