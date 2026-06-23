//
//  FavoriteViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/12/25.
//

import Foundation
import SwiftUI

final class FavoriteViewModel: ObservableObject {
    @Published var favoritesList: [SelectMediaEntity] = []
    private let service: MediaServiceProtocol
    
    init(service: MediaServiceProtocol = MediaService()) {
        self.service = service
    }
    
    func unselect_all() {
        self.favoritesList = self.favoritesList.map { element in
            if element.select == .checked {
                var new_element = element
                new_element.select = .blank
                return new_element
            }
            return element
        }
    }
    
    func setFavorites() {
        self.favoritesList = self.service.fetchFavorites().map({ SelectMediaEntity(media: $0) })
    }
    
//    func add_or_delete_from_favorites(for new_media: MediaEntity) {
//        let select_media = SelectMediaEntity(media: new_media)
//        if new_media.is_favorited { self.add_to_favorites(for: select_media) }
//        else { self.delete_favorited(media: new_media) }
//    }
    
//    private func add_to_favorites(for new_media: SelectMediaEntity) {
//        self.favoritesList.append(new_media)
//    }
//    
//    private func delete_favorited(media: MediaEntity) {
//        if let index = self.favoritesList.firstIndex(where: {$0.id == media.id}) {
//            self.favoritesList.remove(at: index)
//        }
//    }
}
