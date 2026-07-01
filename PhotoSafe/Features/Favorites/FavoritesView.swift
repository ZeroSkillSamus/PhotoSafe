//
//  FavoritesView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct NewHeaderView<Content: View>: View {
    var title: String
    @ViewBuilder var trailingButtons: Content
    var subtitle: Text?
    
    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 35, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.c1_text)
                    
                Spacer()
                
                HStack {
                    trailingButtons
                }
            }
             
            if let subtitle {
                 subtitle
                    .foregroundStyle(Color.c1_text)
                    .font(.system(size: 15,design: .rounded))
                    .opacity(0.7)
                    .frame(maxWidth: .infinity,alignment: .leading)
            }
        }
        .padding(.horizontal)
    }
}

struct FavoritesView: View {
    @EnvironmentObject private var favoritesViewModel: FavoriteViewModel
    @EnvironmentObject private var albumViewModel: AlbumViewModel
    @EnvironmentObject private var slideShowViewModel: SlideShowViewModel
    
    @StateObject private var mediaViewModel: MediaViewModel = MediaViewModel()
    
    var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 3), count: 4)
    @State private var selectedMedia: SelectMediaEntity?
    @State private var mediaSelectedCount: Int = 0
    @State private var toast: ToastItem?
    
    @Binding var isSelectModeActive: Bool
    
    func leadingButton() -> some View {
        Button {
            self.slideShowViewModel.showSlideShowOptions() 
        } label: {
            Image(systemName: "play")
                .foregroundStyle(Color.c1_text)
                .font(.system(size: 17,design: .rounded))
                .padding(.horizontal,12)
                .padding(.vertical,8)
        }
        //.padding(7)
        .applyLiquidGlassIfSupported(shape: .circle, color: Color.c1_accent, isInteractive: true)
        .disabled(self.favoritesViewModel.favoritesList.count <= 1 || self.isSelectModeActive)
        .opacity(self.favoritesViewModel.favoritesList.count <= 1 || self.isSelectModeActive ? 0.3 : 1)
    }
    
    private func trailingButton() -> some View {
        Button {
            // clear selected if cancelling
            if isSelectModeActive {
                self.favoritesViewModel.unSelectAll()
                self.mediaSelectedCount = 0
            }
            
            withAnimation(.easeInOut) {
                self.isSelectModeActive.toggle()
            }
        } label: {
            Text(self.isSelectModeActive ? "Cancel" : "Select")
                .foregroundStyle(Color.c1_text)
                .font(.system(size: 17,design: .rounded))
                .padding(.horizontal,12)
                .padding(.vertical,8)
        }
        .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 10),color: Color.c1_accent, isInteractive: true)
        .disabled(self.favoritesViewModel.favoritesList.isEmpty)
        .opacity(self.favoritesViewModel.favoritesList.isEmpty ? 0.3 : 1)
    }
    
    var subtitle: Text {
        if self.isSelectModeActive {
            if self.mediaSelectedCount == 0 {
                return Text("Tap items to select")
            } else {
                return Text("^[\(mediaSelectedCount) item selected](inflect: true)")
            }
        } else {
            if favoritesViewModel.favoritesList.isEmpty {
                return Text("No favorites yet")
            } else {
                return Text("^[\(favoritesViewModel.favoritesList.count) item](inflect: true)")
            }
        }
    }
    
    var title: String {
        self.isSelectModeActive ? "Select Media" : "Favorites"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NewHeaderView(
                title: self.title,
                trailingButtons: {
                    leadingButton()
                    
                    trailingButton()
                },
                subtitle: subtitle
            )
            
            if favoritesViewModel.favoritesList.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(Color.c1_accent)

                    VStack(spacing: 10) {
                        Text("Tap the heart on photos or videos you want to find faster.")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.c1_text.opacity(0.85))

                        Text("Your favorites will appear here for quick access.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.c1_text.opacity(0.65))
                    }
                    .padding(.horizontal, 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                ScrollView {
                    LazyVGrid(columns: self.gridItemLayout, spacing: 5) {
                        ForEach(self.$favoritesViewModel.favoritesList,id:\.self) { $favorite in
                            if let thumbnailImage = favorite.thumbnailImage {
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
                    .padding(.top, 18)
                    .padding(.horizontal)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            if self.isSelectModeActive {
                Button {
                    do {
                        try self.favoritesViewModel.unFavoriteSelected()
                        self.mediaSelectedCount = 0
                        
                        withAnimation(.easeInOut) { self.isSelectModeActive = false }
                        toast = ToastItem(message: "Removed from Favorites", status: .success)
                    } catch {
                        toast = ToastItem(message: "Failed to remove from favorites", status: .failure)
                    }
                    
                } label: {
                    Text("Unfavorite")
                        .foregroundStyle(Color.c1_text)
                        .font(.system(size: 18,design: .rounded))
                        .padding(.horizontal,15)
                        .padding(.vertical,10)
                        .applyLiquidGlassIfSupported(
                            shape: .rect(cornerRadius: 12),
                            color: Color.c1_accent,
                            isInteractive: true
                        )
                }
                .opacity(self.mediaSelectedCount > 0 ? 1 : 0.3)
                .disabled(self.mediaSelectedCount == 0)
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
        //.orientationLock(.all)
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .background(Color.c1_background)
        .displayToast(self.$toast)
    }
}
