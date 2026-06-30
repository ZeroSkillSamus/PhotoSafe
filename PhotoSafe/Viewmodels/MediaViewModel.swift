//
//  MediaViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import Foundation
import _PhotosUI_SwiftUI
import CoreData

enum VideoFormat {
    case mp4
    case hls
    case unknown
}

@MainActor
final class MediaViewModel: ObservableObject {
    @Published var downloadProgress: [UUID: Double] = [:]
    
    private let mp4DownloadService: VideoDownloaderProtocol
    private let hlsDownloadService: VideoDownloaderProtocol
    private let userDefaults: UserDefaults
    
    @Published var medias: [SelectMediaEntity] = []
    
    @Published private(set) var photo_count: Int = 0
    @Published private(set) var video_count: Int = 0
    @Published private var display_alert: Bool = false
    @Published private(set) var alert_value: Float = 0.0
    @Published var toast: ToastItem?
    
    private var deleteOriginalMediaAfterImport: Bool {
        userDefaults.bool(forKey: StorageKeys.deleteOriginalMediaAfterImport)
    }
    
    // Getter & Setter for display_alert
    var progress_alert: Bool {
        get {
            self.display_alert
        }
        set {
            self.display_alert = newValue
        }
    }
    
    private let service: MediaServiceProtocol
    private let mediaSavingService: MediaHandler
    
    init(
        media_service: MediaServiceProtocol = MediaService(),
        mp4Downloader: VideoDownloaderProtocol = MP4Downloader(),
        hlsDownlaodService: VideoDownloaderProtocol = HLSDownloader(),
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults
        
        self.service = media_service
        self.mp4DownloadService = mp4Downloader
        self.hlsDownloadService = hlsDownlaodService
        self.mediaSavingService = MediaHandler()
    }
    
    var selected_media: [SelectMediaEntity] {
        self.medias.filter({$0.select == .checked})
    }
  
    func reset_alert_value() {
        self.alert_value = 0
    }
    
    func setToast(message: String, status: Status) {
        self.toast = ToastItem(message: message, status: status)
    }
    
    /// Handles exporting media to the users photo library
    /// Still need to implement proper way to relay progress to user
    func exportSelectedMediaToPhotos() async -> (Int, Int) {
        let total = selected_media.count
        
        return await withTaskGroup(of: ToastItem.self) { group in
            for selected in selected_media {
                group.addTask {
                    await self.handleExportingMediaToUserLibrary(selected: selected)
                }
            }
            
            var succeeded = 0
            for await result in group {
                if result.status == .success { succeeded += 1 }
            }
            self.toast = ToastItem(message: "Exported \(succeeded) out of \(total)", status: .success)
            return (succeeded, total)
        }
    }
    
    func exportSingle(selected: SelectMediaEntity) async {
        let success = await handleExportingMediaToUserLibrary(selected: selected)
        self.toast = success
    }
    
    ///
    private func handleExportingMediaToUserLibrary(selected: SelectMediaEntity) async -> ToastItem {
        return await withCheckedContinuation { continuation in
            switch selected.type {
            case MediaType.Photo.rawValue:
                guard let fullImage = selected.fullImage else {
                    continuation.resume(returning: ToastItem(message: "Failed to decode image for export", status: .failure))
                    return
                }
                
                mediaSavingService.savePhotoToUserLibrary(image: fullImage) { toast in
                    continuation.resume(returning: toast)
                }
            case MediaType.Video.rawValue:
                guard let videoPath = selected.videoPath else {
                    continuation.resume(returning: ToastItem(message: "Failed to locate video path for export", status: .failure))
                    return
                }
                
                mediaSavingService.saveVideoToUserLibrary(at: videoPath) { toast in
                    continuation.resume(returning: toast)
                }
            case MediaType.GIF.rawValue:
                mediaSavingService.saveGifToUserLibrary(data: selected.imageData) { toast in
                    continuation.resume(returning: toast)
                }
            default:
                continuation.resume(returning: ToastItem(message: "Unknown media type, can not export", status: .failure))
            }
        }
    }
    
    /// Gets all selected elements
    /// Removes All selected elements from medias
    /// Proceeds to delete them from the coredata
    /// Adjust count to represent the changes
    func delete_selected() throws {
        // Get list of selected items
        try self.selected_media.forEach { selected in
            do {
                try self.service.delete(id: selected.id)
                
                self.delete_from_medias(selected: selected)
            } catch let error {
                throw error
            }
        }
        
        self.set_counts()
    }
    
    func delete(mediaId: UUID) throws {
        do {
            try self.service.delete(id: mediaId)
            
            // Delete from medias array
            self.medias.removeAll(where: {$0.id == mediaId })
        } catch let error {
            throw error
        }
        self.set_counts()
    }
    
    func set_media_and_counts(from album: AlbumEntity) {
        if let medias_sorted = album.sorted_list {
            self.medias = medias_sorted.map({SelectMediaEntity(media: $0)})
        }
        self.set_counts()
    }
    
    func downloadVideoToAlbum(
        id: UUID,
        from urlString: String,
        referer: String?,
        to album: AlbumEntity,
        cookies: [HTTPCookie]?
    ) async -> (ToastItem, MediaEntity?) {
        guard let url = URL(string: urlString) else { return (ToastItem(message: "Url not found!", status: .failure), nil) }
        let videoType = await self.detectVideoFormat(url: url)
        switch videoType {
        case .hls:
            do {
                async let permUrl = self.hlsDownloadService.download(
                    from: url,
                    referrer: cleanUrlForReferer(url: referer),
                    cookies: cookies,
                    onProgress: { [weak self] progress in
                        Task { @MainActor in
                            self?.downloadProgress[id] = progress
                        }
                    })

                guard let location = try await permUrl else {
                    return (ToastItem(message: "Failed to download", status: .failure), nil)
                }

                let fallbackData = UIImage(systemName: "play.rectangle.fill")!.pngData()!
                let imageData = location.generateVideoThumbnail() ?? fallbackData
                let thumbnail = UIImage(data: imageData)?.jpegData(compressionQuality: 0.5) ?? imageData

                let entity = self.add_media(to: album, type: .Video, image_data: imageData, thumbnail: thumbnail, video_path: location.absoluteString)
                return (ToastItem(message: "Successfully Downloaded HLS Video", status: .success), entity)
            } catch (let error) {
                return (ToastItem(message: error.localizedDescription, status: .failure), nil)
            }
        case .mp4:
            // Download the file to a temporary location
            do {
                let permUrl = try await self.mp4DownloadService.download(from: url, referrer: referer, cookies: cookies, onProgress: { [weak self] progress in
                    Task { @MainActor in
                        self?.downloadProgress[id] = progress
                    }
                })
                guard let permUrl else {
                    return (ToastItem(message: "Failed to download", status: .failure), nil)
                }
                if let image_data = permUrl.generateVideoThumbnail() {
                    if let thumbnail = UIImage(data: image_data), let compressed_img = thumbnail.jpegData(compressionQuality: 0.5) {
                       let entity = self.add_media(
                            to: album,
                            type: MediaType.Video,
                            image_data: image_data,
                            thumbnail: compressed_img,
                            video_path: permUrl.absoluteString
                        )
                        return (ToastItem(message: "Successfully Downloaded MP4 Video", status: .success), entity)
                    } else {
                        return (ToastItem(message: "Failed to generate thumbnail", status: .failure), nil)
                    }
                } else {
                    return (ToastItem(message: "Failed to download mp4 video", status: .failure), nil)
                }
            } catch (let error) {
                return (ToastItem(message: error.localizedDescription, status: .failure), nil)
            }
        case .unknown:
            return (ToastItem(message: "Failed to determine video type", status: .failure), nil)
        }
    }
    
    func addPhotoFromWebToAlbum(from urlString: String, to album: AlbumEntity) async -> (ToastItem, MediaEntity?)  {
        self.progress_alert = true
        
        guard let url = URL(string: urlString) else { return (ToastItem(message: "Url not found!", status: .failure), nil) }
        do {
            // Perform the network fetch
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Validate HTTP response status
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return (ToastItem(message: "Server error!", status: .failure), nil)
            }
            
            if let thumbnail = UIImage(data: data)?.thumbnail(), let compressed_img = thumbnail.jpegData(compressionQuality: 0.5)  {
                let entity = self.add_media(
                    to: album,
                    type: data.isGIF  ? .GIF : .Photo,
                    image_data: data,
                    thumbnail: compressed_img
                )
                return (ToastItem(message: "Saved", status: .success), entity)
            }
            
            return (ToastItem(message: "Failed to load image data", status: .failure), nil)
            //
        } catch {
            return (ToastItem(message: "Failed to load image data", status: .failure), nil)
        }
    }
    
    func add_imported_photos(to album: AlbumEntity, from photos_list: [PhotosPickerItem]) async {
        self.reset_alert_value()
        let canDeleteOrignals = await canDeleteOriginals()
        let shouldDeleteOriginals = deleteOriginalMediaAfterImport && canDeleteOrignals
        self.progress_alert = true
        var asset_to_delete: [PHAsset] = []
        
        for item in photos_list {
            // Handle adding to photos list which will be batched delete from user library
            if shouldDeleteOriginals, let identifier = item.itemIdentifier, let asset = mediaSavingService.fetchAsset(with: identifier) {
                asset_to_delete.append(asset)
            }
            
            // Handles Saving Media to CoreData
            do {
                if let video_url = try await item.loadTransferable(type: VideoFileTranferable.self)?.url {
                    if let image_data = video_url.generateVideoThumbnail() {
                        if let thumbnail = UIImage(data: image_data), let compressed_img = thumbnail.jpegData(compressionQuality: 0.5) {
                            let _ = self.add_media(
                                to: album,
                                type: MediaType.Video,
                                image_data: image_data,
                                thumbnail: compressed_img,
                                video_path: video_url.absoluteString
                            )
                        }
                    }
                } else if let image_data = try? await item.loadTransferable(type: Data.self) {
                    // Code determines if image is either a gif
                    let supported_types = item.supportedContentTypes
                    let isGIF = supported_types.contains(UTType.gif)
                    let type = isGIF ? MediaType.GIF : MediaType.Photo
                    if let thumbnail = UIImage(data: image_data)?.thumbnail(), let compressed_img = thumbnail.jpegData(compressionQuality: 0.5)  {
                        let _ = self.add_media(
                            to: album,
                            type: type,
                            image_data: image_data,
                            thumbnail: compressed_img
                        )
                    }
                }
            } catch {}
        }
        if shouldDeleteOriginals {  mediaSavingService.deleteAssets(asset_to_delete) } // Batch delete
        
        // Done Looping, Time to Clear Out SelectedMedia
        self.progress_alert = false
    }
    
    /// Loops through all selected items and attempts to move them to the specified album
    ///   Calls delete_from_medias(selected) to remove from medias array
    func move_selected(to album: AlbumEntity) {
        // Get All Selected Media
        selected_media.forEach { selected in
            do {
                //let media = self.selected_media.first(matchingCategory: selected.id)
                // Fetch media entity to do the move
                try self.service.move(id: selected.id, to: album)
                self.delete_from_medias(selected: selected)
                self.set_counts()
            } catch {}
        }
    }
    
    func move(to album: AlbumEntity, selectedId: UUID) throws {
        do {
            try self.service.move(id: selectedId, to: album)
            
            self.medias.removeAll(where: {$0.id == selectedId})
        } catch let error {
            throw error
        }
    }
  
    /// Depending on what is_select_all is set to we will do the following
    /// If is_select_all is true -> .blank
    /// if is_select_all is false -> .checked
    func change_all(to selector: SelectMediaEntity.Select) {
        self.medias = self.medias.map { media in
            var change_media = media
            change_media.select = selector
            return change_media
        }
    }

    func toggleFavorite(id: UUID, status: FavoriteStatus) -> MediaEntity? {
        do {
            var media: MediaEntity? = nil
            switch status {
            case .Like:
                media = try self.service.favorite(for: id)
            case .Unlike:
                media = try self.service.unfavorite(for: id)
            }
            
            return media
        } catch {
            return nil
        }
    }
    
    private func canDeleteOriginals() async -> Bool {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch currentStatus {
        case .authorized:
            return true

        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized

        case .limited, .denied, .restricted:
            return false

        @unknown default:
            return false
        }
    }
    
    // Added to see if downloading anime was possible
    private func cleanUrlForReferer(url: String?) -> String? {
        return url?.replacingOccurrences(of: "api", with: "") ?? url
    }
    
    private func detectVideoFormat(url: URL) async -> VideoFormat {
        //guard let url = URL(string: urlString) else { return .unknown }

        // Fast path: check path extension (ignores query params)
        let ext = url.pathExtension.lowercased()
        if ext == "mp4" || ext == "mov" { return .mp4 }
        if ext == "m3u8" { return .hls }

        // Fallback: HEAD request for Content-Type
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              let contentType = http.value(forHTTPHeaderField: "Content-Type") else {
            return .unknown
        }

        let ct = contentType.lowercased()
        if ct.contains("video/mp4") || ct.contains("video/quicktime") { return .mp4 }
        if ct.contains("mpegurl") || ct.contains("m3u8") { return .hls }

        return .unknown
    }
    
    private func add_media(
        to album: AlbumEntity,
        type: MediaType,
        image_data: Data,
        thumbnail: Data,
        video_path: String? = nil
    ) -> MediaEntity? {
        if let media_entity = try? self.service.save_media(to: album, type: type, imageData: image_data, thumbnail: thumbnail, videoPath: video_path) {
            let select_media = SelectMediaEntity(media: media_entity)
            self.medias.append(select_media) // add to list
            self.increment_alert_value()
            
            switch type {
            case .Video:
                self.video_count = self.video_count + 1
            case .GIF, .Photo:
                self.photo_count = self.photo_count + 1
            }
            return media_entity
        }
        return nil
    }
    
    private func increment_alert_value() {
        self.alert_value += 1
    }
    
    /// FInds the index of selected and deletes the item at that location from medias
    private func delete_from_medias(selected: SelectMediaEntity) {
        if let index = self.medias.firstIndex(of: selected) {
            self.medias.remove(at: index) //remove from list
            
            //self.medias_dict.removeValue(forKey: selected) // remove from dictionary
        }
    }
    
    ///  Sets the photo_count and video_count
    ///     Note: Photo_Count will count photos and gifs
    private func set_counts() {
        // Set corresponding counts
        self.photo_count = self.medias.filter({$0.type == MediaType.Photo.rawValue || $0.type == MediaType.GIF.rawValue}).count
        self.video_count = self.medias.filter({$0.type == MediaType.Video.rawValue}).count
    }
}
