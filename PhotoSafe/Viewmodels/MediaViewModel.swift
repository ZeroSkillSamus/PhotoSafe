//
//  MediaViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import Foundation
import _PhotosUI_SwiftUI

@MainActor
final class MediaViewModel: ObservableObject {
    @Published var medias_dict: [SelectMediaEntity: UIImage] = [:]
    @Published var medias: [SelectMediaEntity] = []
    
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
    
    init(media_service: MediaServiceProtocol = MediaService()) {
        self.service = media_service
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
        let media_saver = MediaHandler()
        self.selected_media.forEach { selected in
            switch selected.media.type {
            case MediaType.Photo.rawValue:
                if let ui_image = selected.media.image {
                    media_saver.save_photo_to_user_library(image: ui_image)
                }
            case MediaType.Video.rawValue:
                if let path = selected.media.video_path {
                    media_saver.save_video_to_user_library(vid_path: path)
                }
            case MediaType.GIF.rawValue:
                media_saver.save_gif_to_user_library(data: selected.media.image_data)
            default:
                print("Type Not Found!!")
            }
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
        self.medias = self.service.fetch_media(from: album).map {
            return SelectMediaEntity(media: $0)
        }.sorted(by: { a, b in
            a.media.date_added < b.media.date_added
        })
        
        // Populate dictionary
        self.medias.forEach { self.medias_dict[$0] = $0.media.image}
        
        self.set_counts()
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
            if let video_url = try? await item.loadTransferable(type: VideoFileTranferable.self)?.url {
                if let thumbnail = video_url.generateVideoThumbnail() {
                    self.add_media(
                        to: album,
                        type: MediaType.Video,
                        image_data: thumbnail,
                        video_path: video_url.absoluteString
                    )
                }
            }
            else if let image_data = try? await item.loadTransferable(type: Data.self) {
                // Code determines if image is either a gif
                let supported_types = item.supportedContentTypes
                let isGIF = supported_types.contains(UTType.gif)
                let type = isGIF ? MediaType.GIF : MediaType.Photo
                self.add_media(
                    to: album,
                    type: type,
                    image_data: image_data
                )
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
    
    private func add_media(
        to album: AlbumEntity,
        type: MediaType,
        image_data: Data,
        video_path: String? = nil
    ) {
        if let media_entity = try? self.service.save_media(to: album, type: type, imageData: image_data, videoPath: video_path) {
            let select_media = SelectMediaEntity(media: media_entity)
            self.medias.append(select_media) // add to list
            self.medias_dict[select_media] = select_media.media.image // add to dictionary
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
            
            self.medias_dict.removeValue(forKey: selected) // remove from dictionary
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
