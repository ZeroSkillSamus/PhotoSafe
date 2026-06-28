//
//  FavoritesView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favoritesViewModel: FavoriteViewModel
    @EnvironmentObject private var albumViewModel: AlbumViewModel
    @EnvironmentObject private var slideShowViewModel: SlideShowViewModel
    
    @StateObject private var mediaViewModel: MediaViewModel = MediaViewModel()
    
    var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 3), count: 4)
    @State private var selectedMedia: SelectMediaEntity?
    @State private var mediaSelectedCount: Int = 0
    
    @Binding var isSelectModeActive: Bool
    
    func leadingButton() -> some View {
        Button {
            self.slideShowViewModel.showSlideShowOptions() 
        } label: {
            Image(systemName: "play")
                .font(.system(size: 14,design: .rounded))
                //.font(.title2)
                .foregroundColor(Color.c1_text)
        }
        .padding(7)
        .applyLiquidGlassIfSupported(shape: .circle, color: Color.c1_accent, isInteractive: true)
        .disabled(self.favoritesViewModel.favoritesList.isEmpty)
        .opacity(self.favoritesViewModel.favoritesList.isEmpty ? 0.75 : 1)
    }
    
    private func trailingButton() -> some View {
        Button {
            withAnimation(.easeInOut) {
                self.isSelectModeActive.toggle()
            }
        } label: {
            Text(self.isSelectModeActive ? "Cancel" : "Select")
                .foregroundStyle(Color.c1_text)
                .font(.system(size: 14,design: .rounded))
        }
        .padding(7)
        .applyLiquidGlassIfSupported(color: Color.c1_accent, isInteractive: true)
        .disabled(self.favoritesViewModel.favoritesList.isEmpty)
        .opacity(self.favoritesViewModel.favoritesList.isEmpty ? 0.75 : 1)
    }
    
    var header: Text {
        if self.isSelectModeActive {
            if self.mediaSelectedCount == 0 {
                return Text("Select Media")
            } else {
                return Text("^[\(self.mediaSelectedCount) Item](inflect: true) Selected")
            }
        }
        return Text("Favorites")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            UniversalHeader(header: {
                header
                    .default_header()
            }) {
                self.leadingButton()
            } trailing_button: {
                self.trailingButton()
            }

            ScrollView {
                LazyVGrid(columns: self.gridItemLayout, spacing: 3) {
                    ForEach(self.$favoritesViewModel.favoritesList,id:\.self) { $favorite in
                        if let thumbnailImage = favorite.thumbnailImage {
//                            MediaImageGridView(
//                                is_select_mode_active: self.isSelectModeActive,
//                                ui_image: ui_image,
//                                display_if_favorited: false,
//                                media_select: $favorite,
//                                selected_media: self.$selectedMedia,
//                                select_count: self.$mediaSelectedCount
//                            )
                            MediaImageGridView(
                                selectModeActive: self.isSelectModeActive,
                                thumbnail: thumbnailImage,
                                screenType: .Favorite,
                                media: $favorite,
                                selectedMedia: self.$selectedMedia,
                                selectCount: self.$mediaSelectedCount
                            )
                        }
                    }
                }
            }
            
            if self.isSelectModeActive {
                Button {
                    self.favoritesViewModel.unFavoriteSelected()
                    self.mediaSelectedCount = 0
                    
                    withAnimation(.easeInOut) {
                        if self.favoritesViewModel.favoritesList.isEmpty { self.isSelectModeActive.toggle() }
                    }
                    
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.c1_accent)
                        Text("Unfavorite")
                            .font(.system(size: 15,weight: .semibold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }
                    .frame(width: 200,height: 50)
                }
            }
        }
        .fullScreenCover(item: self.$selectedMedia) { element in
            FullCoverSheet(
                screenType: .Favorite,
                mediaViewModel: self.mediaViewModel,
                mediaList: self.$favoritesViewModel.favoritesList,
                selecetedMedia: element
            )
        }
        .fullScreenCover(isPresented: self.$slideShowViewModel.displaySlideshow) {
            AutoScrollerView(orignalList: self.favoritesViewModel.favoritesList)
        }
        .sheet(isPresented: self.$slideShowViewModel.showSettings) {
            OptionsView()
        }
        .orientationLock(.all)
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .background(Color.c1_background)
    }
}




/*
i = 0
total = 45
while i < total {
    i = i + 1
}
 
 #1) 0, 45
 #2) 1, 45
 ...
 
 class Student {
    var name
    var grade
 
    func displayGrade()
    func displayClass()
    func didFail
 }
*/
