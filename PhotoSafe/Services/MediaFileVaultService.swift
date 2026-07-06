//
//  MediaFileService.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 7/5/26.
//

import Foundation

protocol MediaFileVaultProtocol {
    func encryptVideoFile(at sourceURL: URL, id: UUID) throws -> URL
    func decryptVideoFileToTemporaryURL(from encryptedURL: URL, id: UUID) throws -> URL
    func deleteEncryptedVideo(at url: URL) throws
    func deletePlainTextVideo(at url: URL) throws
    func deleteTemporaryPlaybackFile(at url: URL) throws
}

class MediaFileVaultService: MediaFileVaultProtocol {
    static let shared = MediaFileVaultService()

    private let encryptionService: MediaEncryptionServiceProtocol
    private let fileManager: FileManager
    
    init(
        encryptionService: MediaEncryptionServiceProtocol = MediaEncryptionService.shared,
        fileManager: FileManager = .default
    ) {
        self.encryptionService = encryptionService
        self.fileManager = fileManager
    }
    
    func encryptVideoFile(at sourceURL: URL, id: UUID) throws -> URL {
        let originalExtension = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
        
        let videoData = try Data(contentsOf: sourceURL)
        let encryptedData = try encryptionService.encrypt(videoData)
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw MediaEncryptionError.dirCreationFailed
        }
        
        let videosDir = appSupportURL.appendingPathComponent("Videos")
        try fileManager.createDirectory(
            at: videosDir,
            withIntermediateDirectories: true
        )
        
        let destinationURL = videosDir
            .appendingPathComponent("\(id.uuidString).\(originalExtension)")
            .appendingPathExtension("psafe")

        try encryptedData.write(to: destinationURL, options: [.atomic])
        return destinationURL
    }
    
    func decryptVideoFileToTemporaryURL(from encryptedURL: URL, id: UUID) throws -> URL {
        let encryptedData = try Data(contentsOf: encryptedURL)
        let decryptedData = try encryptionService.decrypt(encryptedData)
        let fileExtension = originalExtension(from: encryptedURL)
        
        let tempDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("PhotoSafePlayback", isDirectory: true)

        try fileManager.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )

        let playbackURL = tempDirectory
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension(fileExtension)

        try decryptedData.write(to: playbackURL, options: [.atomic])

        return playbackURL
    }
    
    func deletePlainTextVideo(at url: URL) throws {
        try deleteFileIfExists(at: url)
    }

    func deleteEncryptedVideo(at url: URL) throws {
        try deleteFileIfExists(at: url)
    }

    func deleteTemporaryPlaybackFile(at url: URL) throws {
        try deleteFileIfExists(at: url)
    }
    
    private func originalExtension(from encryptedURL: URL) -> String {
        let filenameWithoutPsafe = encryptedURL.deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: filenameWithoutPsafe).pathExtension
        return ext.isEmpty ? "mp4" : ext
    }
    
    private func deleteFileIfExists(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        try fileManager.removeItem(at: url)
    }
    
}
