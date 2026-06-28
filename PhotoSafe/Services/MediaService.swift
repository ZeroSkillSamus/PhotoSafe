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
    func calculateAllStorageUsed() throws -> MediaStorageSummary?
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
    
    func calculateAllStorageUsed() throws -> MediaStorageSummary? {
        let request = MediaEntity.fetchRequest()
        do {
            let mediaItems = try self.context.fetch(request)
            let fileManager = FileManager.default
            
            var imageBytes: Int64 = 0
            var thumbnailBytes: Int64 = 0
            var videoBytes: Int64 = 0
            
            for media in mediaItems {
                imageBytes += Int64(media.image_data.count)
                thumbnailBytes += Int64(media.thumbnail.count)
                if let videoPath = media.video_path,
                   let url = URL(string: videoPath) {
                    let path = url.isFileURL ? url.path : videoPath

                    if let attributes = try? fileManager.attributesOfItem(atPath: path),
                       let fileSize = attributes[.size] as? NSNumber {
                        videoBytes += fileSize.int64Value
                    }
                }
            }
            
            return MediaStorageSummary(
                mediaCount: mediaItems.count,
                imageBytes: imageBytes,
                thumbnailBytes: thumbnailBytes,
                videoBytes: videoBytes
            )
        } catch (let error) {
            throw error
        }
    }
}
