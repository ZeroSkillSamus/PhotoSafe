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
    
    var is_locked: Bool {
        if let password {
            return password.isEmpty ? false : true
        }
        
        return false 
    }

    @NSManaged public var image: Data?
    @NSManaged public var name: String
    @NSManaged public var password: String?
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
