//
//  FolderService.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/16/26.

import CoreData

enum FolderError: Error {
    case titleTooLong
}

// Define the blueprint for FolderService
protocol FolderServiceProtocol {
    func create(title: String) throws -> FolderEntity
    func fetchAllFolders() -> [FolderEntity]
    func deleteAll() throws
    func delete(folder: FolderEntity) throws
}

final class FolderService: FolderServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.container.viewContext) {
        self.context = context
    }
    
    func create(title: String) throws -> FolderEntity {
        if title.count > 12 {
            throw FolderError.titleTooLong
        }
        
        let folder = FolderEntity(context: self.context)
        folder.title = title
        folder.dateAdded = Date.now
        
        do { try self.context.save() }
        catch (let error) { throw error }
        return folder
    }
    
    func fetchAllFolders() -> [FolderEntity] {
        let fetchRequest: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
        let folders = (try? self.context.fetch(fetchRequest)) ?? []
        return folders
    }
    
    func deleteAll() throws {
        let deleteRequest = FolderEntity.deleteRequest()
        do { try self.context.execute(deleteRequest) }
        catch (let error) { throw error }
    }
    
    func delete(folder: FolderEntity) throws {
        self.context.delete(folder)
        do { try self.context.save() }
        catch (let error) { throw error }
    }
}

