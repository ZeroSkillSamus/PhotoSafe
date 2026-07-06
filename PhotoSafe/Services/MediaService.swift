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
    func save_media(to album: AlbumEntity, id: UUID, type: MediaType, imageData: Data, thumbnail: Data, videoPath: String?) throws -> MediaEntity
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
    private let context: NSManagedObjectContext
    private let encryptionService: MediaEncryptionServiceProtocol
    private let mediaFileVaultService: MediaFileVaultProtocol
    
    init(
        context: NSManagedObjectContext = CoreDataManager.shared.container.viewContext,
        encryptionService: MediaEncryptionServiceProtocol = MediaEncryptionService.shared,
        mediaFileVaultService: MediaFileVaultProtocol = MediaFileVaultService.shared
    ) {
        self.context = context
        self.encryptionService = encryptionService
        self.mediaFileVaultService = mediaFileVaultService
    }
    
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
    
    func save_media(
        to album: AlbumEntity,
        id: UUID = UUID(),
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
        media.image_data = try encryptionService.encrypt(imageData)
        media.type = type.rawValue
        media.video_path = videoPath
        media.is_favorited = false
        media.thumbnail = try encryptionService.encrypt(thumbnail)
        media.id = id
        
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
        let encryptedVideoURL: URL?
        if media.type == MediaType.Video.rawValue, let storedReference = media.video_path {
            encryptedVideoURL = try? MediaStoragePaths.encryptedVideoURL(
                from: storedReference
            )
        } else {
            encryptedVideoURL = nil
        }
        
        self.context.delete(media)
        try self.context.save()
        
        if let encryptedVideoURL {
            try? mediaFileVaultService.deleteEncryptedVideo(at: encryptedVideoURL)
        }
    }
    
    @discardableResult
    func migrateVideoPathsToFilenames() throws -> (
        migrated: Int,
        alreadyCurrent: Int,
        missing: Int
    ) {
        let request = MediaEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "type == %@",
            MediaType.Video.rawValue
        )

        let videos = try context.fetch(request)

        var migrated = 0
        var alreadyCurrent = 0
        var missing = 0

        for media in videos {
            guard let storedReference = media.video_path,
                  !storedReference.isEmpty else {
                missing += 1
                continue
            }

            guard let currentURL = try? MediaStoragePaths.encryptedVideoURL(
                from: storedReference
            ) else {
                // Preserve the original reference for possible recovery.
                missing += 1
                continue
            }

            let filename = currentURL.lastPathComponent

            if storedReference == filename {
                alreadyCurrent += 1
            } else {
                media.video_path = filename
                migrated += 1
            }
        }

        guard context.hasChanges else {
            return (migrated, alreadyCurrent, missing)
        }

        do {
            try context.save()
            return (migrated, alreadyCurrent, missing)
        } catch {
            context.rollback()
            throw error
        }
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
                if media.type == MediaType.Video.rawValue,
                    let lastPathComponent = media.video_path,
                    let videoUrl = try? MediaStoragePaths.encryptedVideoURL(
                        from: lastPathComponent,
                        fileManager: fileManager
                    ),
                    let attributes = try? fileManager.attributesOfItem(atPath: videoUrl.path),
                    let fileSize = attributes[.size] as? NSNumber {
                        videoBytes += fileSize.int64Value
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
