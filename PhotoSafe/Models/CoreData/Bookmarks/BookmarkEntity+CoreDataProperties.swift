//
//  BookmarkEntity+CoreDataProperties.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/15/26.
//

import SwiftUI
import CoreData

@objc(BookmarkEntity)
public class BookmarkEntity: NSManagedObject {

}

extension BookmarkEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BookmarkEntity> {
        return NSFetchRequest<BookmarkEntity>(entityName: "BookmarkEntity")
    }
    
    @nonobjc public class func deleteRequest() -> NSBatchDeleteRequest {
        return NSBatchDeleteRequest(fetchRequest: self.fetchRequest())
    }
    
    var faviconImage: UIImage? {
        guard let favicon  else { return nil }
        return UIImage(data: favicon)
    }
    
    @NSManaged public var dateAdded: Date
    @NSManaged public var favicon: Data?
    @NSManaged public var title: String?
    @NSManaged public var url: URL
    @NSManaged public var folder: FolderEntity?
}

extension BookmarkEntity : Identifiable {

}
