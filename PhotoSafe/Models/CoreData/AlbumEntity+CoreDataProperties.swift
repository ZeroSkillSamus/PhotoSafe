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

// Defined with @objc to allow it to be used with @NSManaged.
enum ImageDisplayType: Int16
{
    case First = 0
    case Last  = 1
    case Upload = 2
    case None = 3
}


extension AlbumEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AlbumEntity> {
        return NSFetchRequest<AlbumEntity>(entityName: "AlbumEntity")
    }
    
    @nonobjc public class func deleteRequest() -> NSBatchDeleteRequest {
        return NSBatchDeleteRequest(fetchRequest: self.fetchRequest())
    }

    var image_upload_status: ImageDisplayType {
        get {
            return ImageDisplayType(rawValue: display_image_status) ?? .None
        }
        set {
            display_image_status = newValue.rawValue
        }
    }
    
    var is_locked: Bool {
        return password.isEmpty ? false : true
    }

    var sorted_list: [MediaEntity]? {
        if let list = media?.allObjects as? [MediaEntity] {
            return list.sorted(by: { a, b in
                a.date_added < b.date_added
            })
        }
        return nil
    }
    
    var fetch_first_image: Data? {
        if let first = self.sorted_list?.first {
            return first.image_data
        }
        return nil
    }
    
    var fetch_last_image: Data? {
        if let last = self.sorted_list?.last {
            return last.image_data
        }
        return nil
    }

    @NSManaged public var image: Data?
    @NSManaged public var name: String
    @NSManaged public var password: String
    @NSManaged public var date_added: Date
    @NSManaged public var media: NSSet?
    @NSManaged private var display_image_status: Int16
    
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
