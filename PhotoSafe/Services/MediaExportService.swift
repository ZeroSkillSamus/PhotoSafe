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
        return await withCheckedContinuation { continuation in
            switch selected.type {
            case MediaType.Photo.rawValue:
                guard let fullImage = selected.fullImage else {
                    continuation.resume(returning: ToastItem(message: "Failed to decode image for export", status: .failure))
                    return
                }
                
                mediaSavingService.savePhotoToUserLibrary(image: fullImage) { toast in
                    continuation.resume(returning: toast)
                }
            case MediaType.Video.rawValue:
                guard let videoPath = selected.videoPath else {
                    continuation.resume(returning: ToastItem(message: "Failed to locate video path for export", status: .failure))
                    return
                }
                
                mediaSavingService.saveVideoToUserLibrary(at: videoPath) { toast in
                    continuation.resume(returning: toast)
                }
            case MediaType.GIF.rawValue:
                mediaSavingService.saveGifToUserLibrary(data: selected.imageData) { toast in
                    continuation.resume(returning: toast)
                }
            default:
                continuation.resume(returning: ToastItem(message: "Unknown media type, can not export", status: .failure))
            }
        }
    }
    
}
