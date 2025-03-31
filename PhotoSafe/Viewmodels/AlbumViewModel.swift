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
    
    func add_media(album: AlbumEntity,type: MediaType,image_data: Data, video_path: String? = nil) -> MediaEntity {
        let media = MediaEntity(context: self.context)
        media.album = album
        media.image_data = image_data
        media.date_added = Date()
        media.video_path = video_path
        media.type = type.rawValue
        self.save()
        
        return media
    }

    func create_album(name: String, image_data: Data?, password: String?) {
        let album = AlbumEntity(context: self.context)
        album.name = name
        album.image = image_data
        album.password = password
        album.date_added = Date()
        
        self.save()
        self.fetch_albums()
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
        do {
            self.albums = try self.context.fetch(AlbumEntity.fetchRequest())
        } catch let error {
            print("Failed To Fetch albums \(error.localizedDescription)")
        }
    }

    private func save() {
        do {
            try self.context.save()
        } catch let error {
            print("Error Saving!: \(error)")
        }
    }
}
