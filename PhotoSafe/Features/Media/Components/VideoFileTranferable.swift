//
//  VideoFileTranferable.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct VideoFileTranferable: Transferable {
    let url: URL

    static var get_application_support_dir: URL {
        let urls = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        let appSupportURL = urls.first!
        
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appSupportURL.path) {
            try? FileManager.default.createDirectory(
                at: appSupportURL,
                withIntermediateDirectories: true
            )
        }
        return appSupportURL
    }
    
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
            
            // 4. COPY (not move) from received location
            try FileManager.default.copyItem(at: received.file, to: permanentURL)

            // 5. Clean up: Remove the temporary file
            try? FileManager.default.removeItem(at: received.file)
            
            // 6. Mark as non-temporary for persistence
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            try? permanentURL.setResourceValues(resourceValues)
            
            return Self(url: permanentURL)
        }
    }
}

