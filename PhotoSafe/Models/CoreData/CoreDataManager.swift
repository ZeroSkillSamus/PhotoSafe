//
//  CoreDataManager.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import CoreData

final class CoreDataManager {
    static let shared = CoreDataManager()
    let container: NSPersistentContainer

    private init() {
        self.container = NSPersistentContainer(name: "Container")
        self.container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load CoreData: \(error)")
            }
        }
    }
}
