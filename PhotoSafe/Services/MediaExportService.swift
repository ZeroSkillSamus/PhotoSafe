//
//  MediaExportService.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 7/4/26.
//

import Foundation

protocol MediaExportServiceProtocol {
    func exportSingle(selected: SelectMediaEntity) async -> ToastItem
    func exportMany(_ selectedMedia: [SelectMediaEntity]) async -> (succeeded: Int, total: Int)
}

struct MediaExportService: MediaExportServiceProtocol {
    private let mediaSavingService: MediaHandler
    
    init(mediaSavingService: MediaHandler = MediaHandler()) {
        self.mediaSavingService = mediaSavingService
    }
    
    func exportMany(_ selectedMedia: [SelectMediaEntity]) async -> (succeeded: Int, total: Int) {
        let total = selectedMedia.count
        
        return await withTaskGroup(of: ToastItem.self) { group in
            for selected in selectedMedia {
                group.addTask {
                    await self.exportToPhotoLibrary(selected: selected)
                }
            }
            
            var succeeded = 0
            for await result in group {
                if result.status == .success { succeeded += 1 }
            }
            //ToastItem(message: "Exported \(succeeded) out of \(total)", status: .success)
            return (succeeded, total)
        }
    }
    
    func exportSingle(selected: SelectMediaEntity) async -> ToastItem {
        await exportToPhotoLibrary(selected: selected)
    }
    
    private func exportToPhotoLibrary(selected: SelectMediaEntity) async -> ToastItem {
        switch selected.type {
        case MediaType.Photo.rawValue:
            guard let fullImage = selected.decryptedFullImage else {
                return ToastItem(message: "Failed to decode image for export", status: .failure)
            }

            return await withCheckedContinuation { continuation in
                mediaSavingService.savePhotoToUserLibrary(image: fullImage) { toast in
                    continuation.resume(returning: toast)
                }
            }

        case MediaType.Video.rawValue:
            let decryptedVideoPath: URL
            guard let lastPathComponent = selected.videoPath else {
                return ToastItem(message: "Failed to locate video path for export", status: .failure)
            }
            
            do {
                let encryptedURL = try MediaStoragePaths.encryptedVideoURL(
                    from: lastPathComponent
                )
                
                decryptedVideoPath = try await Task.detached(priority: .userInitiated) {
                    try MediaFileVaultService.shared.decryptVideoFileToTemporaryURL(
                        from: encryptedURL,
                        id: selected.id
                    )
                }.value
            } catch {
                return ToastItem(message: "Failed to export video", status: .failure)
            }

            return await withCheckedContinuation { continuation in
                mediaSavingService.saveVideoToUserLibrary(at: decryptedVideoPath.path) { toast in
                    try? MediaFileVaultService.shared.deleteTemporaryPlaybackFile(at: decryptedVideoPath)
                    continuation.resume(returning: toast)
                }
            }

        case MediaType.GIF.rawValue:
            guard let decryptedImageData = selected.decryptedImageData else {
                return ToastItem(message: "Failed to decrypt GIF for export", status: .failure)
            }

            return await withCheckedContinuation { continuation in
                mediaSavingService.saveGifToUserLibrary(data: decryptedImageData) { toast in
                    continuation.resume(returning: toast)
                }
            }

        default:
            return ToastItem(message: "Unknown media type, can not export", status: .failure)
        }
    }
}
