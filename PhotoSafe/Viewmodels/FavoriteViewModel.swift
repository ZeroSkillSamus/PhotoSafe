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
    
    func unSelectAll() {
        self.favoritesList = self.favoritesList.map { element in
            if element.select == .checked {
                var new_element = element
                new_element.select = .blank
                return new_element
            }
            return element
        }
    }
    
    func unFavoriteSelected() {
        do {
            defer { self.setFavorites() }
            let selectedList = self.favoritesList.filter({$0.select == .checked })
            for media in selectedList {
                _ = try self.service.unfavorite(for: media.id)
            }
        } catch (let error) {
            print(error.localizedDescription)
        }
    }
    
    func setFavorites() {
        self.favoritesList = self.service.fetchFavorites().map({ SelectMediaEntity(media: $0) })
    }
}
