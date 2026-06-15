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
    
    var toast: ToastItem? = nil
    var folders: [FolderEntity] = []
    var bookmarksNotInFolder: [BookmarkEntity] = []
    
    init(bookmarkService: BookmarkServiceProtocol = BookmarkService()) {
        self.bookmarkService = bookmarkService
        
        // Set Folders & Bookmarks not in folders
        self.setBookmarksNotInFolder()
    }
    
    func setBookmarksNotInFolder() {
        self.bookmarksNotInFolder = self.bookmarkService.fetchAllBookmarksNotInFolder()
    }
    
    func addBookmark(folder: FolderEntity?, url: URL?, favicon: Data?, title: String?) -> ToastItem {
        do {
            let bookmarkEntity = try self.bookmarkService.saveBookmark(folder: folder, url: url, favicon: favicon, title: title)
            if folder == nil {
                self.bookmarksNotInFolder.append(bookmarkEntity)
            }
            
            return ToastItem(message: "Saved to bookmarks", status: .success)
        } catch (let error) {
            print("Failed To Add Bookmark!", error.localizedDescription)
            return ToastItem(message: "Failed to add bookmark", status: .failure)
        }
    }
    
    func deleteAllBookmarksNotInFolder() -> ToastItem {
        do {
            try self.bookmarkService.deleteAllBookmarksNotInAFolder(list: self.bookmarksNotInFolder)
            self.bookmarksNotInFolder.removeAll()
            
            return ToastItem(message: "Deleted all bookmarks not in folders", status: .success)
        } catch (let error) {
            print("Failed to delete bookmarks", error.localizedDescription)
            return ToastItem(message: "Failed to delete bookmarks", status: .failure)
        }
    }
}
