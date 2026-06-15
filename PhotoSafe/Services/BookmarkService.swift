//
//  BookmarkService.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/15/26.
//

import CoreData

// Define the blueprint for AlbumService
protocol BookmarkServiceProtocol {
    func saveBookmark(folder: FolderEntity?, url: URL?, favicon: Data?, title: String?) throws -> BookmarkEntity
    func fetchAllBookmarksNotInFolder() -> [BookmarkEntity]
    func deleteAll() throws
    func deleteAllBookmarksNotInAFolder(list: [BookmarkEntity]) throws
//    func delete(media: MediaEntity) throws
//    func move(media: MediaEntity, to album: AlbumEntity) throws
//    func like_or_unlike(with status: Bool, for media: MediaEntity) throws -> MediaEntity
}

final class BookmarkService: BookmarkServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.container.viewContext) {
        self.context = context
    }
    
    func saveBookmark(folder: FolderEntity?, url: URL?, favicon: Data?, title: String?) throws -> BookmarkEntity {
        guard let url else { throw MediaError.invalidUrl }
        
        let bookmark = BookmarkEntity(context: self.context)
        bookmark.dateAdded = Date.now
        bookmark.favicon = favicon
        bookmark.title = title
        bookmark.url = url
        bookmark.folder = folder
        
        do { try self.context.save() }
        catch (let error) { throw error }
        return bookmark
    }
    
    func fetchAllBookmarksNotInFolder() -> [BookmarkEntity] {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        let bookmarks = (try? self.context.fetch(fetchRequest)) ?? []
        return bookmarks.filter({ $0.folder == nil })
    }
    
    func deleteAllBookmarksNotInAFolder(list: [BookmarkEntity]) throws {
        for bookmark in list {
            self.context.delete(bookmark)
        }
        try self.context.save()
    }
    
    func deleteAll() throws {
        let deleteRequest = BookmarkEntity.deleteRequest()
        do { try self.context.execute(deleteRequest) }
        catch (let error) { throw error }
    }
}
