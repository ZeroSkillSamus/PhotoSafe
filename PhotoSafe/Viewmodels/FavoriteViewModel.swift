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
    @Published var favorites_dict: [SelectMediaEntity: UIImage] = [:]
    @Published var favorites_list: [SelectMediaEntity] = []
    //@Published var favorites: [FavoriteMediaEntity] = []
    private let service: MediaServiceProtocol
    
    init(service: MediaServiceProtocol = MediaService()) {
        self.service = service
    }
    
    func unselect_all() {
        self.favorites_list = self.favorites_list.map { element in
            if element.select == .checked {
                var new_element = element
                new_element.select = .blank
                
                // Need to change map keys
                let old_value = self.favorites_dict[element]
                self.favorites_dict.removeValue(forKey: element) // remove old key
                self.favorites_dict[new_element] = old_value
                
                return new_element
            }
            return element
            
        }
    }
    
    func set_favorites(with albums: [AlbumEntity]) {
        albums.forEach { album in
            if let list = album.sorted_list {
                let media_favorited = list.filter({$0.is_favorited}) //self.favorites.append(contentsOf: list.filter({$0.is_favorited}) )
                media_favorited.forEach { media in
                    let select_media = SelectMediaEntity(media: media)
                    self.favorites_dict[select_media] = select_media.media.image
                    self.favorites_list.append(select_media)
                }
            }
        }
    }
    
    func add_or_delete_from_favorites(for new_media: MediaEntity) {
        let select_media = SelectMediaEntity(media: new_media)
        if new_media.is_favorited { self.add_to_favorites(for: select_media) }
        else { self.delete_favorited(media: select_media) }
    }
    
    private func add_to_favorites(for new_media: SelectMediaEntity) {
        self.favorites_dict[new_media] = new_media.media.image
        self.favorites_list.append(new_media)
    }
    
    private func delete_favorited(media: SelectMediaEntity) {
        self.favorites_dict.removeValue(forKey: media)
        self.favorites_list.removeAll(where: {$0 == media})
    }
}
