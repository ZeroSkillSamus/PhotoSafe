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
    
    func leading_button() -> some View {
        Menu {
            Button {
                print("enable slideshow mode")
            } label: {
                Label("Start SlideShow", systemImage: "play.rectangle.fill")
            }
            
            Button {
                print("enable slideshow mode")
            } label: {
                Label("Vertical View", systemImage: "chevron.up.chevron.down")
            }
            
            Button {
                print("enable slideshow mode")
            } label: {
                Label("Delete All Favorites", systemImage: "trash.fill")
            }

        } label: {
            Image(systemName: "gear")
                .font(.title2)
                .foregroundStyle(Color.c1_text)
        }
    }
    
    private func trailing_button() -> some View {
        Button {
            print("Select")
        } label: {
            Text("Select")
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            UniversalHeader(header: "Favorites") {
                self.leading_button()
            } trailing_button: {
                self.trailing_button()
            }

            ScrollView {
                LazyVGrid(columns: self.gridItemLayout) {
                    ForEach(self.favorites.favorites, id:\.self) { media in
                        if let ui_image = media.image {
                            ImageGridView(
                                ui_image: ui_image,
                                media: media,
                                display_if_favorited: false
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .background(Color.c1_background)
    }
}
