//
//  SettingsView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct MediaStorageSummary {
    let mediaCount: Int
    let imageBytes: Int64
    let thumbnailBytes: Int64
    let videoBytes: Int64

    var totalBytes: Int64 {
        imageBytes + thumbnailBytes + videoBytes
    }
}

enum DestinationChoices: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case photoslibrary = "Photos Library"
    case chosenAlbum = "Photos Album"
    
    var description: String {
        switch self {
        case .photoslibrary:
            return "Save to Recents in the Photos app"
        case .chosenAlbum:
            return "Create or specify a custom album to save media"
        }
    }
}

enum AppDefaults {
    static let values: [String: Any] = [
        StorageKeys.enablePrivacyScreen: true,
        StorageKeys.enableAutoClearingBrowserData: false,
        StorageKeys.enablePrivateBrowser: true,
        StorageKeys.defaultSearchEngine: SearchEngine.duckduckgo.rawValue,
        StorageKeys.deleteOriginalMediaAfterImport: true,
        StorageKeys.exportDestination: DestinationChoices.photoslibrary.rawValue
    ]
    
    static func register() {
        UserDefaults.standard.register(defaults: values)
    }
}

extension Int64 {
    func formattedBytes() -> String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
// Constants for AppStorage keys
enum StorageKeys {
    static let enablePrivacyScreen = "EnablePrivacyScreen"
    static let enableAutoClearingBrowserData = "EnableAutoClearingBrowserData"
    static let defaultSearchEngine = "defaultSearchEngine"
    static let deleteOriginalMediaAfterImport = "deleteOriginalMediaAfterImport"
    static let exportDestination = "exportDestination"
    static let exportAlbumName = "exportAlbumName"
    static let enablePrivateBrowser = "enablePrivateBrowser"
}

enum SearchEngine: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case duckduckgo = "DuckDuckgo"
    case google = "Google"
    case bing = "Bing"
    
    var searchBaseURL: String {
        switch self {
        case .duckduckgo:
            return "https://duckduckgo.com/?q="
        case .google:
            return "https://google.com/search?q="
        case .bing:
            return "https://bing.com/search?q="
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var appSettings: AppSettingsViewModel
    
    @Environment(WebViewModel.self) var webViewModel
    @Environment(FolderBookmarkViewModel.self) var folderBookmarkViewModel
    
    @State private var exportDestinationSheet: Bool = false
    @State private var showConfirmationSheet: Bool = false
    @State private var showDeleteAllConfirmation: Bool = false
    @State private var showDeleteBookmarksAlert: Bool = false
    
    @State private var toast: ToastItem?
    
    //MARK: - Body
    
    var headerSubtitle: Text {
        return Text("Security, browser, and export defaults")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                NewHeaderView(title: "Settings", trailingButtons: { EmptyView() }, subtitle: self.headerSubtitle)
                
                VStack(spacing: 15) {
                    //MARK: -  Security Section
                    SettingsSectionView(
                        content: { self.securityButtons },
                        header: "Security"
                    )
                    
                    // MARK: - Browser Security
                    SettingsSectionView(
                        content: { self.browserButtons },
                        header: "Browser"
                    )
                    
                    // MARK: - Media
                    SettingsSectionView(
                        content: { self.mediaButtons },
                        header: "Media"
                    )
                    
                    SettingsSectionView(
                        content: { self.dangerZoneButtons },
                        header: "Danger Zone",
                        backgroundColor: Color.red
                    )
                    .confirmationDialog(
                        "Delete All Media?",
                        isPresented: $showDeleteAllConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete All Media", role: .destructive) {
                            // require PIN / biometric, then delete
                            self.showConfirmationSheet = true
                        }
                        
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This permanently removes all albums and saved media from PhotoSafe. This cannot be undone.")
                    }
                }
                .padding(.top)
                .padding(.horizontal)
            }
        }
        .displayToast(self.$toast)
        .sheet(isPresented: self.$exportDestinationSheet) {
            ExportDestinationView()
        }
        .sheet(isPresented: self.$showConfirmationSheet) {
            ConfirmPinSheet(toast: self.$toast)
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .background(Color.c1_background)
        .onAppear {
            self.appSettings.setStorageUsage()
        }
        .alert("Delete All Bookmarks?", isPresented: $showDeleteBookmarksAlert) {
            Button("Delete All", role: .destructive) {
                // delete bookmarks/folders here
                self.toast = folderBookmarkViewModel.deleteAllFolders()
                self.folderBookmarkViewModel.setFolders()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes all saved bookmarks and bookmark folders. This cannot be undone.")
        }
        .onChange(of: appSettings.enablePrivateBrowser) { _, _ in
            webViewModel.clearAllCookiesAndCache()
        }
    }
    
    // MARK: - Settings Buttons Views
    
    @ViewBuilder
    var securityButtons: some View {
        NavigationLink(destination: ChangePinView()) {
            SettingsRowView(
                icon: "key.shield.fill",
                title: "Change PIN",
                subtitle: "Update your 6-digit pin",
                trailing: { EmptyView() },
                overlay: { EmptyView() }
            )
        }
        
        Divider().background(Color.c1_text.opacity(0.4)).padding(.horizontal)
        
        SettingsRowView(
            icon: "hand.raised.fill",
            title: "Privacy Screen",
            subtitle: "Hide content when switching apps",
            trailing: { EmptyView() },
            overlay: {
                Toggle(isOn: self.$appSettings.enablePrivacyScreen) {
                    EmptyView()
                }
            }
        )
    }
    
    @ViewBuilder var browserButtons: some View {
        Button {
            webViewModel.clearAllCookiesAndCache()
        } label: {
            SettingsRowView(
                icon: "network.slash",
                title: "Clear browser data",
                subtitle: "Remove cookies, cache, and website data",
                trailing: { EmptyView() },
                overlay: { EmptyView() }
            )
        }
           
        Divider().background(Color.c1_text.opacity(0.4)).padding(.horizontal)
        
        SettingsRowView(
            icon: "lock.doc.fill",
            title: "Clear on Background",
            subtitle: "Clear cookies, cache, and sessions",
            trailing: { EmptyView() },
            overlay: {
                Toggle(isOn: self.$appSettings.enableAutoClearingBrowserData) {
                    EmptyView()
                }
            }
        )
        
        
        Divider().background(Color.c1_text.opacity(0.4)).padding(.horizontal)
        
        SettingsRowView(
            icon: "lock.shield.fill",
            title: "Private Browsing",
            subtitle: "Keep cookies and cache temporary",
            trailing: { EmptyView() },
            overlay: {
                Toggle(isOn: self.$appSettings.enablePrivateBrowser) {
                    EmptyView()
                }
            }
        )
        
        Divider().background(Color.c1_text.opacity(0.4)).padding(.horizontal)
            
        // Default engine picker
        // Default is DuckDuckGo
        SettingsRowView(
            icon: "magnifyingglass",
            title: "Search Engine",
            subtitle: nil,
            trailing: {
                Picker("", selection: self.$appSettings.defaultSearchEngine) {
                    ForEach(SearchEngine.allCases) { engine in
                        Text(engine.rawValue)
                            .tag(engine.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .menuIndicator(.hidden)
                .tint(Color.c1_text)
                .padding(.horizontal, 3)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.c1_primary.opacity(0.12))
                )
            },
            overlay: { EmptyView() }
        )
    }
    
    @ViewBuilder var mediaButtons: some View {
        SettingsRowView(
            icon: "photo",
            title: "Delete media after import",
            subtitle: "Keep your Photo library clean",
            trailing: { EmptyView() },
            overlay: {
                Toggle(isOn: self.$appSettings.deleteOriginalMediaAfterImport) {
                    EmptyView()
                }
            }
        )
        
        Divider().background(Color.c1_text.opacity(0.4)).padding(.horizontal)
        
        // Choose where media gets exported too
        Button {
            self.exportDestinationSheet.toggle()
        } label: {
            SettingsRowView(
                icon: "folder.badge.gearshape",
                title: "Export Destination",
                subtitle: "Choose where exported media is saved",
                trailing: { EmptyView() },
                overlay: {
                    Text(appSettings.currExportDestination)
                    //.frame(alignment: .trailing)
                        .italic(true)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(size: 12))
                        .opacity(0.5)
                        .padding([.bottom,.trailing])
                        .foregroundStyle(Color.c1_text)
                }
            )
        }
        
        
        Divider().background(Color.c1_text.opacity(0.4)).padding(.horizontal)
        
        // Choose where media gets exported too
        SettingsRowView(
            icon: "externaldrive.fill",
            title: "Storage Used",
            subtitle: "Total calculated from videos, gifs, and photos",
            trailing: {
                Text(self.appSettings.mediaStorageSummary?.totalBytes.formattedBytes() ?? "N/A")
                    .font(.system(size: 14,weight: .semibold,design: .rounded))
                    .padding(.horizontal,7)
                    .opacity(0.7)
                    .foregroundStyle(Color.c1_text)
            },
            overlay: { EmptyView() }
        )
    }
    
    @ViewBuilder var dangerZoneButtons: some View {
        Button {
            self.showDeleteAllConfirmation = true
        } label: {
            SettingsRowView(
                icon: "bookmark.slash",
                title: "Delete All Albums & Media",
                subtitle: "Requires additional confirmation",
                trailing: { EmptyView() },
                overlay: { EmptyView() }
            )
        }
        
        Divider().background(Color.c1_text.opacity(0.4)).padding(.horizontal)
        
        Button {
            self.showDeleteBookmarksAlert = true
        } label: {
            SettingsRowView(
                icon: "trash",
                title: "Delete All Bookmarks",
                subtitle: "Bookmarks in folders will also be deleted",
                trailing: { EmptyView() },
                overlay: { EmptyView() }
            )
        }
    }
}
