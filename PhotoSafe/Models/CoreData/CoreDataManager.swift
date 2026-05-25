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

      let storeURL = self.container.persistentStoreDescriptions.first?.url ??
                     NSPersistentContainer.defaultDirectoryURL()
                     .appendingPathComponent("Container.sqlite")
  
      let description = NSPersistentStoreDescription(url: storeURL)
      description.setOption(
          FileProtectionType.complete as NSObject,
          forKey: NSPersistentStoreFileProtectionKey
      )

      self.container.persistentStoreDescriptions = [description]

      self.container.loadPersistentStores { description, error in
          if let error = error {
              fatalError("Failed to load CoreData: \(error)")
          }

          // Exclude CoreData files from iCloud backup
          if var storeURL = description.url {
              let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
              let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")

              for var url in [storeURL, shmURL, walURL] {
                  var resourceValues = URLResourceValues()
                  resourceValues.isExcludedFromBackup = true
                  try? url.setResourceValues(resourceValues)
              }
          }
      }
  }
}
