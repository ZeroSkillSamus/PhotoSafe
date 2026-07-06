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
    func saveAlbum(name: String, thumbnail: Data?, password: String) throws
    func deleteAll() throws
    func delete(album: AlbumEntity) throws
    func change_image_upload_status(for album: AlbumEntity, with new: ImageDisplayType) throws
    func change_photo(for album: AlbumEntity, with data: Data) throws
    func change_name(for album: AlbumEntity, with name: String) throws
    func change_password(for album: AlbumEntity, with password: String) throws
}

final class AlbumService: AlbumServiceProtocol {
    private let context: NSManagedObjectContext
    
    private let mediaFileVaultService: MediaFileVaultProtocol
    private let encryptionService: MediaEncryptionServiceProtocol
    
    init(
        context: NSManagedObjectContext = CoreDataManager.shared.container.viewContext,
        mediaFileVaultService: MediaFileVaultProtocol = MediaFileVaultService.shared,
        encryptionService: MediaEncryptionServiceProtocol = MediaEncryptionService.shared
    ) {
        self.context = context
        self.mediaFileVaultService = mediaFileVaultService
        self.encryptionService = encryptionService
    }
    
    func change_image_upload_status(for album: AlbumEntity, with new: ImageDisplayType) throws {
        album.image_upload_status = new
        if new != .Upload {
            album.thumbnail = nil
        }
        try self.context.save()
    }
    
    func change_password(for album: AlbumEntity, with password: String) throws {
        try setAlbumPassword(for: album, password)
        try context.save()
    }
    
    func change_name(for album: AlbumEntity, with name: String) throws {
        album.name = name
        try context.save()
    }
    
    func change_photo(for album: AlbumEntity, with data: Data) throws {
        album.thumbnail = try encryptionService.encrypt(data)
        try context.save()
    }
    
    func delete(album: AlbumEntity) throws {
        // Fetch all videoUrls so we can delete them
        let videoURLs = encryptedVideoURLs(in: album)
        
        self.context.delete(album)
        try self.context.save()
        
        for videoURL in videoURLs {
            try? self.mediaFileVaultService.deleteEncryptedVideo(at: videoURL)
        }
    }
    
    func fetchAlbums() -> [AlbumEntity] {
        return (try? self.context.fetch(AlbumEntity.fetchRequest())) ?? []
    }
    
    func saveAlbum(name: String, thumbnail: Data?, password: String) throws {
        let albumEntity = AlbumEntity(context: context)
        albumEntity.name = name
        if let thumbnail {
            albumEntity.thumbnail = try encryptionService.encrypt(thumbnail)
        }
        try setAlbumPassword(for: albumEntity, password)
        if thumbnail != nil {
            albumEntity.image_upload_status = .Upload
        } else {
            albumEntity.image_upload_status = .First
        }
        try context.save()
    }
    
    func deleteAll() throws {
        let albums = self.fetchAlbums()
        var videoURLs: [URL] = []
        
        for album in albums {
            videoURLs.append(contentsOf: encryptedVideoURLs(in: album))
            self.context.delete(album)
        }
        try context.save()
        
        for videoURL in videoURLs {
            try? self.mediaFileVaultService.deleteEncryptedVideo(at: videoURL)
        }
    }
    
    private func setAlbumPassword(for albumEntity: AlbumEntity, _ password: String) throws {
        // Need to hash user password and store the hash and salt in coredata
        if password.isEmpty {
            albumEntity.passwordHash = nil
            albumEntity.passwordSalt = nil
        } else {
            let (salt, hashPassword) = try PasswordHasher.hash(password)
            albumEntity.passwordHash = hashPassword
            albumEntity.passwordSalt = salt
        }
    }
    
    private func encryptedVideoURLs(in album: AlbumEntity) -> [URL] {
        album.sorted_list?
            .filter { $0.type == MediaType.Video.rawValue }
            .compactMap { media -> URL? in
                guard let lastPathComponent = media.video_path else { return nil }
                let encryptedVideoURL = try? MediaStoragePaths.encryptedVideoURL(
                    from: lastPathComponent
                )
                return encryptedVideoURL
            } ?? []
    }
}
