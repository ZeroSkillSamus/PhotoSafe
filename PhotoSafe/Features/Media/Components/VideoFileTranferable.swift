//
//  VideoFileTranferable.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct VideoFileTranferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { file in
            // Use COPY instead of MOVE to preserve original
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try FileManager.default.copyItem(at: file.url, to: tempURL)
            return SentTransferredFile(tempURL)
        } importing: { received in
            // 1. Get Application Support directory
            let appSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            
            // 2. Create Videos subdirectory if needed
            let videosDir = appSupportURL.appendingPathComponent("Videos")
            try? FileManager.default.createDirectory(
                at: videosDir,
                withIntermediateDirectories: true
            )
            
            // 3. Create permanent destination URL
            var permanentURL = videosDir
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")

            try FileManager.default.moveItem(at: received.file, to: permanentURL)

            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: permanentURL.path
            )
            
            // 6. Mark as non-temporary for persistence
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? permanentURL.setResourceValues(resourceValues)
            
            return Self(url: permanentURL)
        }
    }
}

