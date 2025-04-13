//
//  FavoriteViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/12/25.
//

import Foundation

final class FavoriteViewModel: ObservableObject {
    @Published var favorites: [MediaEntity] = []
    
    private let service: MediaServiceProtocol
    
    init(service: MediaServiceProtocol = MediaService()) {
        self.service = service
    }
    
    func set_favorites(with albums: [AlbumEntity]) {
        albums.forEach { album in
            if let list = album.sorted_list {
                self.favorites.append(contentsOf: list.filter({$0.is_favorited}) )
            }
        }
    }
    
    func delete_favorited(media: MediaEntity) {
        if let index = self.favorites.firstIndex(of: media) {
            self.favorites.remove(at: index)
        }
    }
}
