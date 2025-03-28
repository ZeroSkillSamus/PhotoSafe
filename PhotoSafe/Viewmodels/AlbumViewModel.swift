//
//  AlbumViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/27/25.
//

import Foundation
import CoreData

//@MainActor
class AlbumViewModel: ObservableObject {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    @Published private(set) var albums: [AlbumEntity] = []
    
    init(){
        self.container = NSPersistentContainer(name: "Container")
        self.container.loadPersistentStores{ (description, error) in
            if let error = error {
                print("Error Loading Container. \(error)")
            } else {
                print("Container Loaded Successfully.")
            }
        }
        self.context = container.viewContext
        
        self.fetch_albums()
    }
    
    func create_album(name: String, image_data: Data?, is_locked: Bool) {
        let album = AlbumEntity(context: self.context)
        album.is_locked = is_locked
        album.name = name
        album.image = image_data
        
        self.save()
    }
    
    func delete_all_albums() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "AlbumEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            self.fetch_albums()
        } catch let error {
            // TODO: handle the error
            print(error.localizedDescription)
        }
    }
    
    private func fetch_albums() {
        let request = NSFetchRequest<AlbumEntity>(entityName: "AlbumEntity")
        do {
            self.albums = try self.context.fetch(request)
        } catch let error {
            print("Failed To Fetch albums \(error.localizedDescription)")
        }
    }
    
    
//    private func download_image(poster_uri: String) async -> NSData? {
//        guard let url = URL(string: poster_uri) else { return nil }
//        var request = URLRequest(url: url)
//        if let referer = referer {
//            request.addValue(referer, forHTTPHeaderField: "REFERER")
//        }
//        do {
//            let (data, _) = try await URLSession.shared.data(for: request)
//            guard let uimage = UIImage(data: data) else {
//                return nil
//            }
//            return uimage.jpegData(compressionQuality: 1) as NSData?
//        } catch let error {
//            print(error)
//        }
//        return nil
//    }
    
    private func save() {
        do {
            try self.context.save()
            self.fetch_albums()
        } catch let error {
            print("Error Saving!: \(error)")
        }
    }
}
