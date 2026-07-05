//
//  FavoriteViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/12/25.
//

import Foundation
import SwiftUI

@MainActor
final class FavoriteViewModel: ObservableObject {
    @Published var favoritesList: [SelectMediaEntity] = []
    private let service: MediaServiceProtocol
    private let mediaExportService: MediaExportServiceProtocol
    
    @Published var toast: ToastItem?
    
    init(
        service: MediaServiceProtocol = MediaService(),
        mediaExportService: MediaExportServiceProtocol = MediaExportService()
    ) {
        self.service = service
        self.mediaExportService = mediaExportService
    }
    
    var selectedMedia: [SelectMediaEntity] {
        self.favoritesList.filter({$0.select == .checked })
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
    
    func unFavoriteSelected() throws {
        do {
            defer { self.setFavorites() }
            let selectedList = self.favoritesList.filter({$0.select == .checked })
            for media in selectedList {
                _ = try self.service.unfavorite(for: media.id)
            }
        } catch (let error){
            throw error
        }
    }
    
    func setFavorites() {
        self.favoritesList = self.service.fetchFavorites().map({ SelectMediaEntity(media: $0) })
    }
    
    func exportSelectedMediaToPhotos() async {
        let selectedMedia = favoritesList.filter({$0.select == .checked })
        let (succeeded, total) =  await self.mediaExportService.exportMany(selectedMedia)
        self.toast = ToastItem(message: "Exported \(succeeded) out of \(total)", status: .success)
    }
}
