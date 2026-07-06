//
//  FavoriteEntity+CoreDataProperties.swift
//  
//
//  Created by Abraham Mitchell on 10/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias FavoriteEntityCoreDataPropertiesSet = NSSet

extension FavoriteEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteEntity> {
        return NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
    }

    @NSManaged public var date_added: String?

}

extension FavoriteEntity : Identifiable {

}
