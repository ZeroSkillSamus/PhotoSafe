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
            let fileManager = FileManager.default

            let stagingDirectory = fileManager.temporaryDirectory
                .appendingPathComponent(
                    "PhotoSafeImports",
                    isDirectory: true
                )

            try fileManager.createDirectory(
                at: stagingDirectory,
                withIntermediateDirectories: true
            )

            let temporaryURL = stagingDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")

            // Move the received file into app-controlled temporary storage.
            try fileManager.moveItem(
                at: received.file,
                to: temporaryURL
            )

            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: temporaryURL.path
            )

            // Temporary directories are already excluded from backup.
            return Self(url: temporaryURL)
        }
    }
}

