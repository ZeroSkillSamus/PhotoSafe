//
//  AlbumViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/27/25.
//

import CoreData

//@MainActor
final class AlbumViewModel: ObservableObject {
    @Published private(set) var albums: [AlbumEntity] = []
    private let service: AlbumServiceProtocol
    
    init(album_service: AlbumServiceProtocol = AlbumService()) {
        self.service = album_service
        self.set_albums()
    }
    
    func set_albums() {
        self.albums = service.fetchAlbums()
    }
    
    func delete(album: AlbumEntity) {
        try? self.service.delete(album: album)
        self.set_albums()
    }

    func create_album(name: String, image_data: Data?, password: String?) {
        try? service.saveAlbum(
            name: name,
            image_data: image_data,
            password: password
        )
        
        self.set_albums()
    }

    func deleteAll() {
        try? self.service.deleteAll() //Attempt to delete all albums
        
        self.set_albums()
    }
}
