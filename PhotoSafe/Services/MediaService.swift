//
//  MediaServi e.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import CoreData

// Custom error type
enum MediaError: Error {
    case invalidImageData
}

// Define the blueprint for AlbumService
protocol MediaServiceProtocol {
    func save_media(to album: AlbumEntity, type: MediaType, imageData: Data, videoPath: String?) throws -> MediaEntity
    func fetch_media(from album: AlbumEntity) -> [MediaEntity]
    func delete(media: MediaEntity) throws
}

final class MediaService: MediaServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.container.viewContext) {
        self.context = context
    }
    
    func save_media(
        to album: AlbumEntity,
        type: MediaType,
        imageData: Data,
        videoPath: String? = nil
    ) throws -> MediaEntity {
        guard !imageData.isEmpty else {
            throw MediaError.invalidImageData
        }
        
        let media = MediaEntity(context: self.context)
        media.date_added = Date()
        media.album = album
        media.image_data = imageData
        media.type = type.rawValue
        media.video_path = videoPath
        
        try self.context.save()
        return media
    }
    
    func fetch_media(from album: AlbumEntity) -> [MediaEntity] {
        let medias = (try? self.context.fetch(MediaEntity.fetchRequest())) ?? []
        return medias.filter({ $0.album.name == album.name })
    }
    
    func delete(media: MediaEntity) throws {
        self.context.delete(media)
        try self.context.save()
    }
    
    
}
