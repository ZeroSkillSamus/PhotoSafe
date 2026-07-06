//
//  AlbumImageDisplay.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/6/25.
//

import SwiftUI

struct AlbumImageDisplay: View {
    @ObservedObject var album: AlbumEntity
    var corner_radius: CGFloat = 2
    
    @ViewBuilder
    func display_image_view(with ui_image: UIImage? = nil) -> some View {
        if let ui_image, !self.album.is_locked {
            Image(uiImage: ui_image).resizable().clipShape(RoundedRectangle(cornerRadius: corner_radius))
        } else if self.album.is_locked {
            ZStack {
                RoundedRectangle(cornerRadius: corner_radius).fill(Color.c1_primary)
                Image(systemName: "lock.fill").font(.title.bold()).foregroundStyle(Color.c1_accent)
            }
        } else {
            Image("NoImageFound").resizable().clipShape(RoundedRectangle(cornerRadius: corner_radius))
        }
                
    }
    
    private func decryptedThumbnail(media: MediaEntity?) -> UIImage? {
        guard let media else { return nil }
        do {
            let data = try MediaEncryptionService.shared.decrypt(media.thumbnail)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
    
    var body: some View {
        switch album.image_upload_status {
        case .First:
            if let ui_image = decryptedThumbnail(media: album.firstMediaInAlbum) {
                display_image_view(with: ui_image)
            } else {
                display_image_view()
            }
        case .Last:
            if let ui_image = decryptedThumbnail(media: album.lastMediaInAlbum) {
                display_image_view(with: ui_image)
            } else {
                display_image_view()
            }
        case .Upload:
            if let ui_image = album.uploaded_thumbnail_image {
                display_image_view(with: ui_image)
            } else {
                display_image_view()
            }
        case .None:
            display_image_view()
        }
    }
}
