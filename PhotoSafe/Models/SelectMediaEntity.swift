//
//  SelectMediaEntity.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct SelectMediaEntity: Hashable, Identifiable {
    enum Select {
        case checked
        case blank
    }
    var select: Select = .blank
    
    var id: UUID
    var imageData: Data
    var dateAdded: Date
    var type: String
    var videoPath: String?
    var albumName: String
    var isFavorited: Bool
    var thumbnail: Data
    
    init(media: MediaEntity, select: Select = .blank) {
        self.select = select
        self.id = media.id
        self.imageData = media.image_data
        self.dateAdded = media.date_added
        self.type = media.type
        self.videoPath = media.video_path
        self.albumName = media.album.name
        self.isFavorited = media.is_favorited
        self.thumbnail = media.thumbnail
    }
    
    var thumbnailImage: UIImage? {
        UIImage(data: thumbnail)
    }

    var fullImage: UIImage? {
        UIImage(data: imageData)
    }
}
