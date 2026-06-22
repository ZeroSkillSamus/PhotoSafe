//
//  VideoDownloaderProtocol.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/18/26.
//

import SwiftUI
import AVKit
import ffmpegkit

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

class HLSDownloader: VideoDownloaderProtocol {

    enum HLSError: Error {
        case failed
    }

    func download(from url: URL, referrer: String?, cookies: [HTTPCookie]?, onProgress: ((Double) -> Void)?) async throws -> URL? {
        let fm = FileManager.default
        let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let videosDir = appSupportURL.appendingPathComponent("Videos")
        try? fm.createDirectory(at: videosDir, withIntermediateDirectories: true)
        let outputURL = videosDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")

        let headersArg = buildHeadersArg(referrer: referrer, cookies: cookies)
        let totalMs = await probeDurationMs(urlString: url.absoluteString, headersArg: headersArg)

        let cmd = "\(headersArg)-i \"\(url.absoluteString)\" -map 0:v? -map 0:a? -c copy -movflags faststart \"\(outputURL.path)\""

        return try await withCheckedThrowingContinuation { continuation in
            FFmpegKit.executeAsync(cmd, withCompleteCallback: { session in
                guard let session else { continuation.resume(returning: nil); return }
                if ReturnCode.isSuccess(session.getReturnCode()) {
                    try? fm.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: outputURL.path)
                    var rv = URLResourceValues()
                    rv.isExcludedFromBackup = true
                    var out = outputURL
                    try? out.setResourceValues(rv)
                    onProgress?(1.0)
                    continuation.resume(returning: outputURL)
                } else {
                    continuation.resume(throwing: HLSError.failed)
                }
            }, withLogCallback: nil, withStatisticsCallback: { stats in
                guard let stats, let onProgress, let total = totalMs, total > 0 else { return }
                onProgress(min(Double(stats.getTime()) / Double(total), 0.99))
            })
        }
    }

    // Returns "-headers \"Key: val\r\n\" " (with trailing space) or "" if no headers
    private func buildHeadersArg(referrer: String?, cookies: [HTTPCookie]?) -> String {
        var lines = ""
        if let referrer { lines += "Referer: \(referrer)\r\n" }
        if let cookies, !cookies.isEmpty {
            lines += "Cookie: \(cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; "))\r\n"
        }
        return lines.isEmpty ? "" : "-headers \"\(lines)\" "
    }

    private func probeDurationMs(urlString: String, headersArg: String) async -> Int64? {
        return await withCheckedContinuation { continuation in
            FFprobeKit.getMediaInformationAsync(urlString) { session in
                guard let info = session?.getMediaInformation(),
                      let durationStr = info.getDuration(),
                      let durationSec = Double(durationStr) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: Int64(durationSec * 1000))
            }
        }
    }
}
