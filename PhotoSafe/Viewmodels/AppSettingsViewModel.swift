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
}
