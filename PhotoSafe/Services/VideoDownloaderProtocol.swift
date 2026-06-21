//
//  VideoDownloaderProtocol.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/18/26.
//

import SwiftUI
import AVKit

protocol VideoDownloaderProtocol {
    func download(from url: URL, referrer: String?, cookies: [HTTPCookie]?, onProgress: ((Double) -> Void)?) async throws -> URL?
}

class MP4Downloader: NSObject, VideoDownloaderProtocol, URLSessionDownloadDelegate {
    private var continuation: CheckedContinuation<URL?, Error>?
    private var onProgress: ((Double) -> Void)?
    private var session: URLSession?
    
    func download(from url: URL, referrer: String?, cookies: [HTTPCookie]?, onProgress: ((Double) -> Void)?) async throws -> URL? {
        self.onProgress = onProgress
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                let config = URLSessionConfiguration.default
                self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)

                var request = URLRequest(url: url)
                if let referrer { request.setValue(referrer, forHTTPHeaderField: "Referer") }
                if let cookies, !cookies.isEmpty {
                    let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                    request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
                }
                session?.downloadTask(with: request).resume()
            }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        onProgress?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }
    
    // Move file and resume continuation
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let videosDir = appSupportURL.appendingPathComponent("Videos")
            try? FileManager.default.createDirectory(at: videosDir, withIntermediateDirectories: true)

            var permanentURL = videosDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
            try FileManager.default.moveItem(at: location, to: permanentURL)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: permanentURL.path)

            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try permanentURL.setResourceValues(resourceValues)

            continuation?.resume(returning: permanentURL)
        } catch {
            continuation?.resume(throwing: error)
        }
      continuation = nil
    }
    
    // Error delegate 
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

class HLSDownloader: NSObject, ObservableObject, AVAssetDownloadDelegate, VideoDownloaderProtocol {
    private var continuation: CheckedContinuation<URL?, Error>?
    private var session: AVAssetDownloadURLSession?

    private var onProgress: ((Double) -> Void)?
    
    // MARK: - Error Handling
    enum ConversionError: Error {
        case exportSessionCreationFailed
        case exportFailed(Error?)
        case exportCancelled
        case invalidAsset
        case directoryCreationFailed
    }
    
    func download(from url: URL, referrer: String?, cookies: [HTTPCookie]?, onProgress: ((Double) -> Void)?) async throws -> URL? {
        self.onProgress = onProgress
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
        onProgress?(Double(percentComplete))
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
