//
//  FavoritesView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoriteViewModel
    @EnvironmentObject private var albums: AlbumViewModel
    
    var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 3), count: 4)
    var body: some View {
        VStack {
            ForEach(self.favorites.favorites, id:\.self) { media in
                if let ui_image = media.image {
                    LazyVGrid(columns: self.gridItemLayout) {
                        Image(uiImage: ui_image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .scaleEffect(1.3)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(alignment: .topLeading) {
                                VStack {
                                    if media.type == MediaType.Video.rawValue {
                                        Image(systemName: "video.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                                .padding(5)
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .background(Color.c1_background)
    }
}
//
//#Preview {
//    FavoritesView()
//}
