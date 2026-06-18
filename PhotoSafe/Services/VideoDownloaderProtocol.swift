//
//  VideoDownloaderProtocol.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/18/26.
//

import SwiftUI

protocol VideoDownloaderProtocol {
    func download(from url: URL, referrer: String?, cookies: [HTTPCookie]?) async throws -> URL?
}

class MP4Downloader: VideoDownloaderProtocol {
    func download(from url: URL, referrer: String?, cookies: [HTTPCookie]?) async throws -> URL? {
        do {
            var request = URLRequest(url: url)
              
            if let referrer {
                request.setValue(referrer, forHTTPHeaderField: "Referer")
            }

            if let cookies, !cookies.isEmpty {
                let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
            }

            let (tempURL, _) = try await URLSession.shared.download(for: request)
            //let (tempURL, _) = try await URLSession.shared.downloadTask(with: request)
//            let ext = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
            
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
                .appendingPathExtension("mp4")

            try FileManager.default.moveItem(at: tempURL, to: permanentURL)
            
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: permanentURL.path
            )
            
            // 6. Mark as non-temporary for persistence
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try permanentURL.setResourceValues(resourceValues)
            
            return permanentURL
        } catch (let error) {
            throw error
        }
    }
}

class HLSDownloader: VideoDownloaderProtocol {
    func download(from url: URL, referrer: String?, cookies: [HTTPCookie]?) async throws -> URL? {
        return nil
    }
}
