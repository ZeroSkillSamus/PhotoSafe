//
//  AlbumImageDisplay.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/6/25.
//

import SwiftUI

struct AlbumImageDisplay: View {
    var body: some View {
        if let image_data = album.image, let ui_image = UIImage(data: image_data) {
            Image(uiImage: ui_image)
                .resizable()
                .scaledToFill()
        } else {
            if !album.is_locked ,let data = album.fetch_first_image, let ui_image = UIImage(data: data) {
                Image(uiImage: ui_image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("NoImageFound")
                    .resizable()
                    .scaledToFill()
            }
        }
    }
}

#Preview {
    AlbumImageDisplay()
}
