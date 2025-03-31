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
    
    private let service: MediaServiceProtocol
    
    init(media_service: MediaServiceProtocol = MediaService()) {
        self.service = media_service
    }
    
    func set_media_and_counts(from album: AlbumEntity) {
        self.medias = self.service.fetch_media(from: album).map {
            return SelectMediaEntity(media: $0)
        }.sorted(by: { a, b in
            a.media.date_added < b.media.date_added
        })
        
        // Set corresponding counts
        self.photo_count = self.medias.filter({$0.media.type == MediaType.Photo.rawValue || $0.media.type == MediaType.GIF.rawValue}).count
        self.video_count = self.medias.filter({$0.media.type == MediaType.Video.rawValue}).count
    }
    
    func add_media(
        to album: AlbumEntity,
        type: MediaType,
        image_data: Data,
        video_path: String? = nil
    ) {
        if let media_entity = try? self.service.save_media(to: album, type: type, imageData: image_data, videoPath: video_path) {
            self.medias.append(SelectMediaEntity(media: media_entity))
        }
        
        switch type {
        case .Video:
            self.video_count = self.video_count + 1
        case .GIF, .Photo:
            self.photo_count = self.photo_count + 1
        }
    }
}
