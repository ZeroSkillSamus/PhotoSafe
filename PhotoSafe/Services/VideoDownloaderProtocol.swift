//
//  VideoDownloaderProtocol.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/18/26.
//

import SwiftUI
import AVKit

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

class HLSDownloader: NSObject, ObservableObject, AVAssetDownloadDelegate, VideoDownloaderProtocol {
    private var continuation: CheckedContinuation<URL?, Error>?
    private var session: AVAssetDownloadURLSession?

    
    // MARK: - Error Handling
    enum ConversionError: Error {
        case exportSessionCreationFailed
        case exportFailed(Error?)
        case exportCancelled
        case invalidAsset
        case directoryCreationFailed
    }
    
    func download(from url: URL, referrer: String?, cookies: [HTTPCookie]?) async throws -> URL? {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let config = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
            self.session = AVAssetDownloadURLSession(
              configuration: config,
              assetDownloadDelegate: self,
              delegateQueue: .main
            )

            // Add headers to the urlasset
            var headers: [String: String] = [:]
            if let referrer { headers["Referer"] = referrer }
            if let cookies, !cookies.isEmpty {
                headers["Cookie"] = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            }
            print(headers)
            print(url.absoluteString)
            let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
            let task = self.session?.makeAssetDownloadTask(
              asset: asset,
              assetTitle: "HLS Video",
              assetArtworkData: nil,
              options: nil
            )
            task?.resume()
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad expectedTimeRange: CMTimeRange) {
        
        // Calculate and publish your download progress here
        let percentComplete = loadedTimeRanges.reduce(0) { total, range in
            total + range.timeRangeValue.duration.seconds
        } / expectedTimeRange.duration.seconds
        
        print("Download Progress: \(percentComplete * 100)%")
    }

    // MARK: - AVAssetDownloadDelegate
        func urlSession(
            _ session: URLSession,
            assetDownloadTask: AVAssetDownloadTask,
            didFinishDownloadingTo location: URL
        ) {
            // Apply protection
            let fm = FileManager.default
            if let enumerator = fm.enumerator(at: location, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    try? fm.setAttributes(
                        [.protectionKey: FileProtectionType.complete],
                        ofItemAtPath: fileURL.path
                    )
                }
            }
            
            let homeURL = URL(fileURLWithPath: NSHomeDirectory())
            let absoluteURL = homeURL.appendingPathComponent(location.relativePath)
            continuation?.resume(returning: absoluteURL)
            continuation = nil
        }
}
