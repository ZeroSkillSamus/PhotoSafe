//
//  AlbumService.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import Foundation
import CoreData

// Define the blueprint for AlbumService
protocol AlbumServiceProtocol {
    func fetchAlbums() -> [AlbumEntity]
    func saveAlbum(name: String, image_data: Data?, password: String?) throws
    func deleteAll() throws
}

final class AlbumService: AlbumServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchAlbums() -> [AlbumEntity] {
        return (try? self.context.fetch(AlbumEntity.fetchRequest())) ?? []
    }
    
    func saveAlbum(name: String, image_data: Data?, password: String?) throws {
        let albumEntity = AlbumEntity(context: context)
        albumEntity.name = name
        albumEntity.image = image_data
        albumEntity.password = password
        
        try context.save()
    }
    
    func deleteAll() throws {
        let deleteRequest = AlbumEntity.deleteRequest()
        try self.context.execute(deleteRequest)
    }
}
