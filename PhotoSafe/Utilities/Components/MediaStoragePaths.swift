//
//  MediaStoragePaths.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 10/7/26.
//

import Foundation

enum MediaStoragePaths {
    static func videosDirectory(
        fileManager: FileManager = .default
    ) throws -> URL {
        guard let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw MediaEncryptionError.dirCreationFailed
        }

        return applicationSupport
            .appendingPathComponent("Videos", isDirectory: true)
    }

    static func ensureVideosDirectory(
        fileManager: FileManager = .default
    ) throws -> URL {
        let directory = try videosDirectory(fileManager: fileManager)

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }
    
    static func encryptedVideoURL(
        from storedReference: String,
        fileManager: FileManager = .default
    ) throws -> URL {
        let filename =
            URL(string: storedReference)?.lastPathComponent
            ?? URL(fileURLWithPath: storedReference).lastPathComponent

        guard !filename.isEmpty else {
            throw MediaError.invalidUrl
        }

        let fileURL = try MediaStoragePaths.videosDirectory(
            fileManager: fileManager
        )
        .appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw MediaError.invalidUrl
        }

        return fileURL
    }
}
