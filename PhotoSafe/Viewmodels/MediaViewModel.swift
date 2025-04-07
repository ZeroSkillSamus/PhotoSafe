//
//  MediaViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import Foundation

struct SelectMediaEntity: Hashable, Identifiable {
    var id: UUID = UUID()
    
    enum Select {
        case checked
        case blank
    }
    
    var media: MediaEntity
    var select: Select = .blank
}

final class MediaViewModel: ObservableObject {
    @Published var medias: [SelectMediaEntity] = []
    
    @Published private(set) var photo_count: Int = 0
    @Published private(set) var video_count: Int = 0
    @Published private(set) var display_alert: Bool = false
    @Published private(set) var alert_value: Float = 0.0

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
        
        self.set_counts()
    }
    
    func add_media(
        to album: AlbumEntity,
        type: MediaType,
        image_data: Data,
        video_path: String? = nil
    ) {
        if let media_entity = try? self.service.save_media(to: album, type: type, imageData: image_data, videoPath: video_path) {
            self.medias.append(SelectMediaEntity(media: media_entity))
            self.increment_alert_value()
            
            switch type {
            case .Video:
                self.video_count = self.video_count + 1
            case .GIF, .Photo:
                self.photo_count = self.photo_count + 1
            }
            
        }
    }
    
    /// Loops through all selected items and attempts to move them to the specified album
    ///   Calls delete_from_medias(selected) to remove from medias array
    func move_selected(to album: AlbumEntity) {
        // Get All Selected Media
        selected_media.forEach { selected in
            do {
                try self.service.move(media: selected.media, to: album)
                self.delete_from_medias(selected: selected)
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

    private func increment_alert_value() {
        self.alert_value += 1
    }
    
    /// FInds the index of selected and deletes the item at that location from medias
    private func delete_from_medias(selected: SelectMediaEntity) {
        if let index = self.medias.firstIndex(of: selected) {
            self.medias.remove(at: index)
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
