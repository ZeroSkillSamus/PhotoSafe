//
//  AlbumViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/27/25.
//

import Foundation
import CoreData

//@MainActor
class AlbumViewModel: ObservableObject {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    @Published private(set) var albums: [AlbumEntity] = []
    @Published private(set) var media_entity: [MediaEntity] = []
    
    init(){
        self.container = NSPersistentContainer(name: "Container")
        self.container.loadPersistentStores{ (description, error) in
            if let error = error {
                print("Error Loading Container. \(error)")
            } else {
                print("Container Loaded Successfully.")
            }
        }
        self.context = container.viewContext
        
        self.fetch_albums()
    }
    
    func create_album(name: String, image_data: Data?, is_locked: Bool, password: String?) {
        let album = AlbumEntity(context: self.context)
        album.is_locked = is_locked
        album.name = name
        album.image = image_data
        album.password = password
        
        self.save()
    }
    
    func delete_all_albums() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "AlbumEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            self.fetch_albums()
        } catch let error {
            // TODO: handle the error
            print(error.localizedDescription)
        }
    }
    
    private func fetch_albums() {
        let request = NSFetchRequest<AlbumEntity>(entityName: "AlbumEntity")
        do {
            self.albums = try self.context.fetch(request)
        } catch let error {
            print("Failed To Fetch albums \(error.localizedDescription)")
        }
    }

    private func save() {
        do {
            try self.context.save()
            self.fetch_albums()
        } catch let error {
            print("Error Saving!: \(error)")
        }
    }
}
