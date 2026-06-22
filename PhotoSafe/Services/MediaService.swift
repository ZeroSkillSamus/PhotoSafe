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
    case invalidUrl
    case failedFetch
}

// Define the blueprint for AlbumService
protocol MediaServiceProtocol {
    func save_media(to album: AlbumEntity, type: MediaType, imageData: Data, thumbnail: Data, videoPath: String?) throws -> MediaEntity
    func fetch_media(from album: AlbumEntity) -> [MediaEntity]
    func fetchAll() -> [MediaEntity]
    func delete(id: UUID) throws
    func move(id: UUID, to album: AlbumEntity) throws
    func fetchFavorites() -> [MediaEntity]
    func favorite(for id: UUID) throws -> MediaEntity
    func unfavorite(for id: UUID) throws -> MediaEntity
    //func fetchById(id: UUID) throws -> MediaEntity?
}

final class MediaService: MediaServiceProtocol {
    private func fetchById(id: UUID) throws -> MediaEntity? {
        let request = MediaEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let media = try? context.fetch(request).first else { return nil }
        return media
    }
    
    func favorite(for id: UUID) throws -> MediaEntity {
        do {
            guard let mediaEntity = try self.fetchById(id: id) else { throw MediaError.failedFetch }
            
            mediaEntity.is_favorited = true
            try self.context.save()
            return mediaEntity
        } catch (let error) {
            throw error
        }
    }
    
    func unfavorite(for id: UUID) throws -> MediaEntity {
        do {
            guard let mediaEntity = try self.fetchById(id: id) else { throw MediaError.failedFetch }
            
            mediaEntity.is_favorited = false
            try self.context.save()
            return mediaEntity
        } catch (let error) {
            throw error
        }
    }
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.container.viewContext) {
        self.context = context
    }
    
//    func like_or_unlike(with status: Bool, for id: UUID) throws -> MediaEntity {
//        do {
//            guard let media = try self.context.fetch(MediaEntity.fetchRequest()).first(where: { $0.id == id }) else {
//                throw MediaError.failedFetch
//            }
//            
//            media.is_favorited = status
//            try self.context.save()
//            return media
//        } catch (let error) {
//            throw error
//        }
//    }
    
    func save_media(
        to album: AlbumEntity,
        type: MediaType,
        imageData: Data,
        thumbnail: Data,
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
        media.is_favorited = false
        media.thumbnail = thumbnail
        media.id = UUID() 
        
        try self.context.save()
        return media
    }
    
    func fetch_media(from album: AlbumEntity) -> [MediaEntity] {
        let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
        let medias = (try? self.context.fetch(fetchRequest)) ?? []
        return medias.filter({ $0.album.name == album.name })
    }
    
    func fetchAll() -> [MediaEntity] {
        let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
        let medias = (try? self.context.fetch(fetchRequest)) ?? []
        return medias
    }
    
    func delete(id: UUID) throws {
        guard let media = try? self.context.fetch(MediaEntity.fetchRequest()).first(where: { $0.id == id }) else { return }
        
        self.context.delete(media)
        try self.context.save()
    }
    
    func move(id: UUID, to album: AlbumEntity) throws {
        guard let media = try? self.context.fetch(MediaEntity.fetchRequest()).first(where: { $0.id == id }) else { return }
        
        media.album = album
        media.date_added = Date()
        try self.context.save()
    }
    
    func fetchFavorites() -> [MediaEntity] {
        let request = MediaEntity.fetchRequest()
        request.predicate = NSPredicate(format: "is_favorited == YES")
        return (try? context.fetch(request)) ?? []
    }
}
