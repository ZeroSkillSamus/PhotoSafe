//
//  ImageGridView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/14/25.
//

import SwiftUI

struct ImageGridView: View {
    let ui_image: UIImage
    let media: MediaEntity
    
    var display_if_favorited: Bool = true
    
    var show_background: Bool {
        media.is_favorited || media.type == MediaType.Video.rawValue
    }
    
    var body: some View {
        Image(uiImage: ui_image)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .scaleEffect(1.3)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(alignment: .topLeading) {
                if show_background {
                    HStack {
                        if media.type == MediaType.Video.rawValue {
                            Image(systemName: "video.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        
                        Spacer()
                        
                        if media.is_favorited && display_if_favorited {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                                .font(.caption)
                        }
                    }
                    .padding(5)
                    .background(!(media.is_favorited && display_if_favorited) ? .clear : .black.opacity(0.30))
                }
            }
    }
}
