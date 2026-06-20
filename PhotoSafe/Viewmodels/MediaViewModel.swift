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
    private let mp4DownloadService: VideoDownloaderProtocol
    private let hlsDownloadService: VideoDownloaderProtocol
    
    @Published var medias: [SelectMediaEntity] = []
    @Published var test_media: [MediaEntity] = []
    @Published var test: [UIImage] = []
    
    @Published private(set) var photo_count: Int = 0
    @Published private(set) var video_count: Int = 0
    @Published private var display_alert: Bool = false
    @Published private(set) var alert_value: Float = 0.0
    @Published var export_finished: Bool = false
    
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
    
    init(media_service: MediaServiceProtocol = MediaService(), mp4Downloader: VideoDownloaderProtocol = MP4Downloader(), hlsDownlaodService: VideoDownloaderProtocol = HLSDownloader()) {
        self.service = media_service
        self.mp4DownloadService = mp4Downloader
        self.hlsDownloadService = hlsDownlaodService
    }
    
    var selected_media: [SelectMediaEntity] {
        self.medias.filter({$0.select == .checked})
    }
  
    func reset_alert_value() {
        self.alert_value = 0
    }
    
    /// Handles exporting media to the users photo library
    /// Still need to implement proper way to relay progress to user
    func export_selected_media_to_photo_library() {
        self.selected_media.forEach { selected in
            self.export_media_to_library(selected: selected)
        }
    }
    
    ///
    func export_media_to_library(selected: SelectMediaEntity) {
        let media_saver = MediaHandler()
        switch selected.media.type {
        case MediaType.Photo.rawValue:
            if let ui_image = selected.media.full_image {
                media_saver.save_photo_to_user_library(image: ui_image)
            }
        case MediaType.Video.rawValue:
            if let vid_path = selected.media.video_path {
                media_saver.saveVideoToUserLibrary(at: vid_path)
            }
        case MediaType.GIF.rawValue:
            media_saver.save_gif_to_user_library(data: selected.media.image_data)
        default:
            print("Type Not Found!!")
        }
        self.export_finished = true
    }
    
    /// Gets all selected elements
    /// Removes All selected elements from medias
    /// Proceeds to delete them from the coredata
    /// Adjust count to represent the changes
    func delete_selected() {
        // Get list of selected items
        self.selected_media.forEach { selected in
            do {
                try self.service.delete(media: selected.media)
                
                self.delete_from_medias(selected: selected)
            } catch let error {
                print("\(error)")
            }
        }
        
        self.set_counts()
    }
    
    func set_media_and_counts(from album: AlbumEntity) {
        if let medias_sorted = album.sorted_list {
            self.medias = medias_sorted.map({SelectMediaEntity(media: $0)})
        }
        self.set_counts()
    }
    
    func downloadVideoToAlbum(from urlString: String, referer: String?, to album: AlbumEntity, cookies: [HTTPCookie]?) async -> ToastItem {
        guard let url = URL(string: urlString) else { return ToastItem(message: "Url not found!", status: .failure) }
        let videoType = await self.detectVideoFormat(url: url)
        switch videoType {
        case .hls:
            do {
                async let permUrl = self.hlsDownloadService.download(from: url, referrer: cleanUrlForReferer(url: referer), cookies: cookies)

                guard let location = try await permUrl else {
                    return ToastItem(message: "Failed to download", status: .failure)
                }

                let imageData = UIImage(systemName: "play.rectangle.fill")!.pngData()!
                let thumbnail = UIImage(data: imageData)?.jpegData(compressionQuality: 0.5) ?? imageData

                self.add_media(to: album, type: .Video, image_data: imageData, thumbnail: thumbnail, video_path: location.absoluteString)
                return ToastItem(message: "Successfully Downloaded HLS Video", status: .success)
            } catch (let error) {
                print("Failed to download hls video", error)
                return ToastItem(message: error.localizedDescription, status: .failure)
            }
        case .mp4:
            // Download the file to a temporary location
            do {
                let permUrl = try await self.mp4DownloadService.download(from: url, referrer: referer, cookies: cookies)
                guard let permUrl else {
                    return ToastItem(message: "Failed to download", status: .failure)
                }
                print(permUrl)
                if let image_data = permUrl.generateVideoThumbnail() {
                    if let thumbnail = UIImage(data: image_data), let compressed_img = thumbnail.jpegData(compressionQuality: 0.5) {
                        self.add_media(
                            to: album,
                            type: MediaType.Video,
                            image_data: image_data,
                            thumbnail: compressed_img,
                            video_path: permUrl.absoluteString
                        )
                        return ToastItem(message: "Successfully Downloaded MP4 Video", status: .success)
                    } else {
                        return ToastItem(message: "Failed to generate thumbnail", status: .failure)
                    }
                } else {
                    return ToastItem(message: "Failed to download mp4 video", status: .failure)
                }
            } catch (let error) {
                print("Failed to download mp4 video", error)
                return ToastItem(message: error.localizedDescription, status: .failure)
            }
        case .unknown:
            return ToastItem(message: "Failed to determine video type", status: .failure)
        }
    }
    
    func addPhotoFromWebToAlbum(from urlString: String, to album: AlbumEntity) async -> ToastItem  {
        self.progress_alert = true
        
        guard let url = URL(string: urlString) else { return ToastItem(message: "Url not found!", status: .failure) }
        do {
            // Perform the network fetch
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Validate HTTP response status
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Server error")
                return ToastItem(message: "Server error!", status: .failure)
            }
            
            if let thumbnail = UIImage(data: data)?.thumbnail(), let compressed_img = thumbnail.jpegData(compressionQuality: 0.5)  {
                self.add_media(
                    to: album,
                    type: data.isGIF  ? .GIF : .Photo,
                    image_data: data,
                    thumbnail: compressed_img
                )
                return ToastItem(message: "Saved", status: .success)
            }
            
            print("Failed to load image data: \(url.absoluteString)")
            return ToastItem(message: "Failed to load image data", status: .failure)
            //
        } catch {
            print("Failed to load image data: \(error.localizedDescription)")
            return ToastItem(message: "Failed to load image data", status: .failure)
        }
    }
    
    func add_imported_photos(to album: AlbumEntity, from photos_list: [PhotosPickerItem]) async {
        self.reset_alert_value()
        self.progress_alert = true
        var asset_to_delete: [PHAsset] = []
        
        for item in photos_list {
            // Handle adding to photos list which will be batched delete from user library
            if let identifier = item.itemIdentifier, let asset = MediaHandler.fetchAsset(with: identifier) {
                asset_to_delete.append(asset)
            }
            
            // Handles Saving Media to CoreData
            do {
                if let video_url = try await item.loadTransferable(type: VideoFileTranferable.self)?.url {
                    if let image_data = video_url.generateVideoThumbnail() {
                        if let thumbnail = UIImage(data: image_data), let compressed_img = thumbnail.jpegData(compressionQuality: 0.5) {
                            self.add_media(
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
                        self.add_media(
                            to: album,
                            type: type,
                            image_data: image_data,
                            thumbnail: compressed_img
                        )
                    }
                }
            } catch(let error) {
                print("Video load failed: \(error)")
            }
        }
        
        // Batch delete
        MediaHandler.deleteAssets(asset_to_delete)
        
        // Done Looping, Time to Clear Out SelectedMedia
        self.progress_alert = false
    }
    
    /// Loops through all selected items and attempts to move them to the specified album
    ///   Calls delete_from_medias(selected) to remove from medias array
    func move_selected(to album: AlbumEntity) {
        // Get All Selected Media
        selected_media.forEach { selected in
            do {
                try self.service.move(media: selected.media, to: album)
                self.delete_from_medias(selected: selected)
                self.set_counts()
            } catch let error {
                print("Error \(error)")
            }
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

    func favorite_media(for media: MediaEntity, with status: Bool) -> MediaEntity {
        do {
            let media = try self.service.like_or_unlike(with: status, for: media)
            return media
        } catch {
            return media
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
    ) {
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
            
        }
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
        self.photo_count = self.medias.filter({$0.media.type == MediaType.Photo.rawValue || $0.media.type == MediaType.GIF.rawValue}).count
        self.video_count = self.medias.filter({$0.media.type == MediaType.Video.rawValue}).count
    }
}
