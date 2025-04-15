//
//  FavoriteViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/12/25.
//

import Foundation
import SwiftUI

final class FavoriteViewModel: ObservableObject {
    //@Published var favorites: [MediaEntity] = []
    @Published var favorites: [MediaEntity: UIImage] = [:]
    private let service: MediaServiceProtocol
    
    init(service: MediaServiceProtocol = MediaService()) {
        self.service = service
    }
    
    func set_favorites(with albums: [AlbumEntity]) {
        albums.forEach { album in
            if let list = album.sorted_list {
                let media_favorited = list.filter({$0.is_favorited}) //self.favorites.append(contentsOf: list.filter({$0.is_favorited}) )
                media_favorited.forEach { media in
                    self.favorites[media] = media.image
                }
            }
        }
    }
    
    func add_or_delete_from_favorites(for new_media: MediaEntity) {
        if new_media.is_favorited { self.add_to_favorites(for: new_media) }
        else { self.delete_favorited(media: new_media) }
    }
    
    private func add_to_favorites(for new_media: MediaEntity) {
        self.favorites[new_media] = new_media.image
    }
    
    private func delete_favorited(media: MediaEntity) {
        self.favorites.removeValue(forKey: media)
    }
}
