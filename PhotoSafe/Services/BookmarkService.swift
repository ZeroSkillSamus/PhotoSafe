//
//  BookmarkService.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/15/26.
//

import CoreData

// Define the blueprint for BookmarkService
protocol BookmarkServiceProtocol {
    func saveBookmark(folder: FolderEntity?, url: URL?, favicon: Data?, title: String?) throws -> BookmarkEntity
    func fetchAllBookmarksNotInFolder() -> [BookmarkEntity]
    func fetchBookmarksInFolder(folder: FolderEntity) -> [BookmarkEntity]
    func deleteAll() throws
    func deleteBatchOfBookmarks(list: [BookmarkEntity]) throws
    func delete(bookmark: BookmarkEntity) throws
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
        let bookmarks = self.fetchAll()
        return bookmarks.filter({ $0.folder == nil })
    }
    
    func fetchBookmarksInFolder(folder: FolderEntity) -> [BookmarkEntity] {
        let bookmarks = self.fetchAll()
        return bookmarks.filter({ $0.folder == folder })
    }
    
    func deleteBatchOfBookmarks(list: [BookmarkEntity]) throws {
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
    
    func delete(bookmark: BookmarkEntity) throws {
        self.context.delete(bookmark)
        do { try self.context.save() }
        catch (let error) { throw error }
    }
    
    private func fetchAll() -> [BookmarkEntity] {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        let bookmarks = (try? self.context.fetch(fetchRequest)) ?? []
        
        return bookmarks
        //return bookmarks.filter({ $0.folder == nil })
    }
    
}
