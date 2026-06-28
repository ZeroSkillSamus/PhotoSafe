//
//  ImageGridView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/14/25.
//

import SwiftUI

struct ImageGridView: View {
    let thumbnail: UIImage
    let media: SelectMediaEntity
    
    var screenType: ScreenType
    //var display_if_favorited: Bool = true
    
    var showBackground: Bool {
        media.isFavorited || media.type == MediaType.Video.rawValue
    }
    
    var isFavoritesAndScreenTypeMedia: Bool {
        media.isFavorited && screenType == .Media
    }
    
    var body: some View {
        Image(uiImage: thumbnail)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .scaleEffect(1.1)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(alignment: .topLeading) {
                if showBackground {
                    HStack {
                        if media.type == MediaType.Video.rawValue {
                            Image(systemName: "video.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        
                        Spacer()
                        
                        if self.isFavoritesAndScreenTypeMedia {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                                .font(.caption)
                        }
                    }
                    .padding(5)
                    .background(!(isFavoritesAndScreenTypeMedia) ? .clear : .black.opacity(0.30))
                }
            }
    }
}
