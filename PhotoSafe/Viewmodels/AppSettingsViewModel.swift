//
//  AppSettingsViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/29/26.
//

import Foundation

@MainActor
final class AppSettingsViewModel: ObservableObject {
    private let userDefaults: UserDefaults
    private let mediaService: MediaServiceProtocol
   
    @Published var mediaStorageSummary: MediaStorageSummary?
    
    @Published var enablePrivacyScreen: Bool {
        didSet {
            userDefaults.set(enablePrivacyScreen, forKey: StorageKeys.enablePrivacyScreen)
        }
    }
    
    @Published var enablePrivateBrowser: Bool {
        didSet {
            userDefaults.set(enablePrivateBrowser, forKey: StorageKeys.enablePrivateBrowser)
        }
    }
    
    @Published var deleteOriginalMediaAfterImport: Bool {
        didSet {
            userDefaults.set(deleteOriginalMediaAfterImport, forKey: StorageKeys.deleteOriginalMediaAfterImport)
        }
    }
    
    @Published var defaultSearchEngine: String {
        didSet {
            userDefaults.set(defaultSearchEngine, forKey: StorageKeys.defaultSearchEngine)
        }
    }
    
    @Published var enableAutoClearingBrowserData: Bool {
        didSet {
            userDefaults.set(enableAutoClearingBrowserData, forKey: StorageKeys.enableAutoClearingBrowserData)
        }
    }
    
    @Published var exportDestination: String {
        didSet {
            userDefaults.set(exportDestination, forKey: StorageKeys.exportDestination)
        }
    }

    @Published var exportAlbumName: String {
        didSet {
            userDefaults.set(exportAlbumName, forKey: StorageKeys.exportAlbumName)
        }
    }
    
    init(
        userDefaults: UserDefaults = .standard,
        mediaService: MediaServiceProtocol = MediaService()
    ) {
        self.userDefaults = userDefaults
        self.mediaService = mediaService
        self.enablePrivacyScreen = userDefaults.object(forKey: StorageKeys.enablePrivacyScreen) as? Bool ?? true
        self.enableAutoClearingBrowserData = userDefaults.object(forKey: StorageKeys.enableAutoClearingBrowserData) as? Bool ?? false
        self.defaultSearchEngine = userDefaults.object(forKey: StorageKeys.defaultSearchEngine) as? String ?? SearchEngine.duckduckgo.rawValue
        self.deleteOriginalMediaAfterImport = userDefaults.object(forKey: StorageKeys.deleteOriginalMediaAfterImport) as? Bool ?? true
        
        self.exportDestination = userDefaults.object(forKey: StorageKeys.exportDestination) as? String ?? "Photos Library"
        self.exportAlbumName = userDefaults.object(forKey: StorageKeys.exportAlbumName) as? String ?? ""
        
        self.enablePrivateBrowser = userDefaults.object(forKey: StorageKeys.enablePrivateBrowser) as? Bool ?? true
    }
    
    func setStorageUsage() {
        self.mediaStorageSummary = try? mediaService.calculateAllStorageUsed()
        printStorageDebugBreakdown()
    }
    
    var currExportDestination: String {
        guard let exportDestination = DestinationChoices(rawValue: self.exportDestination) else { return DestinationChoices.photoslibrary.rawValue }
        switch exportDestination {
        case .chosenAlbum:
            return exportAlbumName
            // Display name from user
        case .photoslibrary:
            return DestinationChoices.photoslibrary.rawValue
        }
    }

    private func printStorageDebugBreakdown() {
        let fileManager = FileManager.default
        let mediaTotal = mediaStorageSummary?.totalBytes ?? 0
        let imageBytes = mediaStorageSummary?.imageBytes ?? 0
        let thumbnailBytes = mediaStorageSummary?.thumbnailBytes ?? 0
        let videoBytes = mediaStorageSummary?.videoBytes ?? 0

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
        let temporaryURL = fileManager.temporaryDirectory
        let videosURL = applicationSupportURL?.appendingPathComponent("Videos", isDirectory: true)
        let playbackURL = temporaryURL.appendingPathComponent("PhotoSafePlayback", isDirectory: true)
        let webKitURL = libraryURL?.appendingPathComponent("WebKit", isDirectory: true)

        let documentsSize = storageSize(at: documentsURL)
        let applicationSupportSize = storageSize(at: applicationSupportURL)
        let cachesSize = storageSize(at: cachesURL)
        let temporarySize = storageSize(at: temporaryURL)
        let videosSize = storageSize(at: videosURL)
        let playbackSize = storageSize(at: playbackURL)
        let webKitSize = storageSize(at: webKitURL)
        let commonContainerTotal = documentsSize.logicalBytes
            + applicationSupportSize.logicalBytes
            + cachesSize.logicalBytes
            + temporarySize.logicalBytes
            + webKitSize.logicalBytes

        print("""

        [PhotoSafe Storage Debug]
        Media rows: \(mediaStorageSummary?.mediaCount ?? 0)
        App Settings media total: \(mediaTotal.formattedBytes())
          - Images in Core Data: \(imageBytes.formattedBytes())
          - Thumbnails in Core Data: \(thumbnailBytes.formattedBytes())
          - Referenced video files: \(videoBytes.formattedBytes())

        Container folders, logical size:
          - Documents: \(documentsSize.logicalBytes.formattedBytes())
          - Application Support: \(applicationSupportSize.logicalBytes.formattedBytes())
          - Application Support/Videos: \(videosSize.logicalBytes.formattedBytes())
          - Caches: \(cachesSize.logicalBytes.formattedBytes())
          - Library/WebKit: \(webKitSize.logicalBytes.formattedBytes())
          - tmp: \(temporarySize.logicalBytes.formattedBytes())
          - tmp/PhotoSafePlayback: \(playbackSize.logicalBytes.formattedBytes())

        Container folders, allocated size:
          - Documents: \(documentsSize.allocatedBytes.formattedBytes())
          - Application Support: \(applicationSupportSize.allocatedBytes.formattedBytes())
          - Application Support/Videos: \(videosSize.allocatedBytes.formattedBytes())
          - Caches: \(cachesSize.allocatedBytes.formattedBytes())
          - Library/WebKit: \(webKitSize.allocatedBytes.formattedBytes())
          - tmp: \(temporarySize.allocatedBytes.formattedBytes())
          - tmp/PhotoSafePlayback: \(playbackSize.allocatedBytes.formattedBytes())

        Common container total, excluding app bundle: \(commonContainerTotal.formattedBytes())
        Unreferenced video/temp hint:
          - Videos folder minus referenced videos: \((videosSize.logicalBytes - videoBytes).formattedBytes())
          - tmp playback files: \(playbackSize.logicalBytes.formattedBytes())
        [/PhotoSafe Storage Debug]

        """)
    }

    private func storageSize(at url: URL?) -> (logicalBytes: Int64, allocatedBytes: Int64) {
        guard let url else {
            return (0, 0)
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return (0, 0)
        }

        if !isDirectory.boolValue {
            return fileSize(at: url)
        }

        let keys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .fileSizeKey,
            .totalFileAllocatedSizeKey,
            .fileAllocatedSizeKey
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [],
            errorHandler: { url, error in
                print("[PhotoSafe Storage Debug] Failed to inspect \(url.path): \(error.localizedDescription)")
                return true
            }
        ) else {
            return (0, 0)
        }

        var logicalBytes: Int64 = 0
        var allocatedBytes: Int64 = 0

        for case let fileURL as URL in enumerator {
            let size = fileSize(at: fileURL)
            logicalBytes += size.logicalBytes
            allocatedBytes += size.allocatedBytes
        }

        return (logicalBytes, allocatedBytes)
    }

    private func fileSize(at url: URL) -> (logicalBytes: Int64, allocatedBytes: Int64) {
        do {
            let values = try url.resourceValues(forKeys: [
                .isRegularFileKey,
                .fileSizeKey,
                .totalFileAllocatedSizeKey,
                .fileAllocatedSizeKey
            ])

            guard values.isRegularFile == true else {
                return (0, 0)
            }

            let logicalBytes = Int64(values.fileSize ?? 0)
            let allocatedBytes = Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? values.fileSize ?? 0)
            return (logicalBytes, allocatedBytes)
        } catch {
            print("[PhotoSafe Storage Debug] Failed to read file size for \(url.path): \(error.localizedDescription)")
            return (0, 0)
        }
    }
}
