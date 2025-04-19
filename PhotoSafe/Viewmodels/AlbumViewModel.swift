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
    
    func change_upload_status(for album: AlbumEntity, with new: ImageDisplayType) {
        try? self.service.change_image_upload_status(for: album, with: new)
        self.set_albums()
    }
    
    func change_password(for album: AlbumEntity, with password: String) {
        try? self.service.change_password(for: album, with: password)
        self.set_albums()
    }
    
    func change_name(for album: AlbumEntity, with name: String) {
        try? self.service.change_name(for: album, with: name)
        self.set_albums()
    }
    
    func change_image(for album: AlbumEntity, with image_data: Data) {
        try? self.service.change_photo(for: album, with: image_data)
        self.set_albums()
    }
    
    func set_albums() {
        self.albums = service.fetchAlbums()
    }
    
    func delete(album: AlbumEntity) {
        try? self.service.delete(album: album)
        self.set_albums()
    }

    func create_album(name: String, thumbnail: Data?, password: String) {
        do {
            try service.saveAlbum(
                name: name,
                thumbnail: thumbnail,
                password: password
            )
            self.set_albums()
            
        } catch let error {
            print(error)
        }
        
        
    }

    func deleteAll() {
        try? self.service.deleteAll() //Attempt to delete all albums
        
        self.set_albums()
    }
}
