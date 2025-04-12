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
    func saveAlbum(name: String, image_data: Data?, password: String) throws
    func deleteAll() throws
    func delete(album: AlbumEntity) throws
    func change_image_upload_status(for album: AlbumEntity, with new: ImageDisplayType) throws
    func change_photo(for album: AlbumEntity, with data: Data) throws
    func change_name(for album: AlbumEntity, with name: String) throws
    func change_password(for album: AlbumEntity, with password: String) throws
}

final class AlbumService: AlbumServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.container.viewContext) {
        self.context = context
    }
    
    func change_image_upload_status(for album: AlbumEntity, with new: ImageDisplayType) throws {
        album.image_upload_status = new
        if new != .Upload {
            album.image = nil
        }
        try self.context.save()
    }
    
    func change_password(for album: AlbumEntity, with password: String) throws {
        album.password = password
        try context.save()
    }
    
    func change_name(for album: AlbumEntity, with name: String) throws {
        album.name = name
        try context.save()
    }
    
    func change_photo(for album: AlbumEntity, with data: Data) throws {
        album.image = data
        try context.save()
    }
    
    func delete(album: AlbumEntity) throws {
        self.context.delete(album)
        try self.context.save()
    }
    
    func fetchAlbums() -> [AlbumEntity] {
        return (try? self.context.fetch(AlbumEntity.fetchRequest())) ?? []
    }
    
    func saveAlbum(name: String, image_data: Data?, password: String) throws {
        let albumEntity = AlbumEntity(context: context)
        albumEntity.name = name
        albumEntity.image = image_data
        albumEntity.password = password
        
        if image_data != nil {
            albumEntity.image_upload_status = .Upload
        } else {
            albumEntity.image_upload_status = .First
        }
        try context.save()
    }
    
    func deleteAll() throws {
        let deleteRequest = AlbumEntity.deleteRequest()
        try self.context.execute(deleteRequest)
    }
}
