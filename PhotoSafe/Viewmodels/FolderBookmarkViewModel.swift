//
//  BookmarkViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/15/26.
//

import Foundation

@Observable
class FolderBookmarkViewModel {
    private let bookmarkService: BookmarkServiceProtocol
    private let folderService: FolderServiceProtocol
    
    var toast: ToastItem? = nil
    
    var folders: [FolderEntity] = []
    //var bookmarksNotInFolder: [BookmarkEntity] = []
    
    init(bookmarkService: BookmarkServiceProtocol = BookmarkService(), folderService: FolderServiceProtocol = FolderService()) {
        self.bookmarkService = bookmarkService
        self.folderService = folderService
        
        // Set All Folders
        self.setFolders()
    }
    
    func setFolders() {
        self.folders = self.folderService.fetchAllFolders()
    }
    
    // MARK: - Folder Handlers
    func addFolder(name: String) -> ToastItem {
        do {
            let folderEntity = try self.folderService.create(title: name)
            self.folders.append(folderEntity)
            
            return ToastItem(message: "Created Folder!", status: .success)
        } catch (let error) {
            print("Failed To create folder!", error.localizedDescription)
            return ToastItem(message: "Failed to create folder", status: .failure)
        }
    }
    
    func deleteAllFolders() -> ToastItem {
        do {
            try self.folderService.deleteAll()
            return ToastItem(message: "Deleted all Folders!", status: .success)
        } catch (let error) {
            print("Failed To delete all folders", error.localizedDescription)
            return ToastItem(message: "Failed to delete all folders", status: .failure)
        }
    }
    
    // MARK: - Bookmark Handlers
    func fetchBookmarksIn(folder: FolderEntity) -> [BookmarkEntity] {
        self.bookmarkService.fetchBookmarksInFolder(folder: folder)
    }
    
    func fetchBookmarksNotInFolder() -> [BookmarkEntity] {
        self.bookmarkService.fetchAllBookmarksNotInFolder()
    }
    
    func addBookmark(folder: FolderEntity?, url: URL?, favicon: Data?, title: String?) -> ToastItem {
        do {
            _ = try self.bookmarkService.saveBookmark(folder: folder, url: url, favicon: favicon, title: title)
            return ToastItem(message: "Saved to bookmarks", status: .success)
        } catch (let error) {
            print("Failed To Add Bookmark!", error.localizedDescription)
            return ToastItem(message: "Failed to add bookmark", status: .failure)
        }
    }
    
    func deleteBatchOfBookmarks(in folder: FolderEntity?) -> ToastItem {
        do {
            let bookmarks = folder == nil ? self.bookmarkService.fetchAllBookmarksNotInFolder() : self.bookmarkService.fetchBookmarksInFolder(folder: folder!)
            
            try self.bookmarkService.deleteBatchOfBookmarks(list: bookmarks)
           
            return ToastItem(message: "Deleted all bookmarks not in folders", status: .success)
        } catch (let error) {
            print("Failed to delete bookmarks", error.localizedDescription)
            return ToastItem(message: "Failed to delete bookmarks", status: .failure)
        }
    }
    
    func deleteBookmark(bookmark: BookmarkEntity) -> ToastItem {
        do {
            try self.bookmarkService.delete(bookmark: bookmark)
            // Delete from array
            return ToastItem(message: "Deleted bookmark", status: .success)
        } catch (let error) {
            print("Failed to delete bookmarks", error.localizedDescription)
            return ToastItem(message: "Failed to delete bookmark", status: .failure)
        }
    }
}
