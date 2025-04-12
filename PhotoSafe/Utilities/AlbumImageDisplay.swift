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
            Image(uiImage: ui_image).resizable()
        } else if self.album.is_locked {
            ZStack {
                RoundedRectangle(cornerRadius: corner_radius).fill(Color.c1_primary)
                Image(systemName: "lock.fill").font(.title.bold()).foregroundStyle(Color.c1_accent)
            }
        } else {
            Image("NoImageFound").resizable()
        }
                
    }
    
    var body: some View {
        switch album.image_upload_status {
        case .First:
            if let first_image_data = album.fetch_first_image, let ui_image = UIImage(data: first_image_data) {
                display_image_view(with: ui_image)
            } else {
                display_image_view()
            }
        case .Last:
            if let last_image_data = album.fetch_last_image, let ui_image = UIImage(data: last_image_data) {
                display_image_view(with: ui_image)
            } else {
                display_image_view()
            }
        case .Upload:
            if let image_data = album.image, let ui_image = UIImage(data: image_data){
                display_image_view(with: ui_image)
            } else {
                display_image_view()
            }
        case .None:
            display_image_view()
        }
    }
}
