//
//  FolderEntity+CoreDataProperties.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/15/26.
//

import SwiftUI
import CoreData

@objc(FolderEntity)
public class FolderEntity: NSManagedObject {

}

extension FolderEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FolderEntity> {
        return NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
    }
    
    @nonobjc public class func deleteRequest() -> NSBatchDeleteRequest {
        return NSBatchDeleteRequest(fetchRequest: self.fetchRequest())
    }
    
    @NSManaged public var dateAdded: Date
    @NSManaged public var title: String
    @NSManaged public var bookmarks: NSSet?
}

extension FolderEntity : Identifiable {

}
