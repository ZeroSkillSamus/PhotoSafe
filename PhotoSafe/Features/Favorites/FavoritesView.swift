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
    @State private var disableScrollView: Bool = false
    
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
    
    private var stickyHeader: some View {
        HStack {
            // Recenlty Delete Shower
            leadingButton()
            
            Spacer()
            
            trailingButton()
        }
        .overlay(alignment: .center, content: {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                if self.mediaSelectedCount > 0 {
                    subtitle
                        .font(.system(size: 13, design: .rounded))
                        .opacity(0.7)
                }
            }
            
        })
        .foregroundStyle(Color.c1_text)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.c1_secondary)
    }
    
    var body: some View {
        StickyHeaderWrapper(
            shouldDisableScrollView: self.favoritesViewModel.favoritesList.isEmpty,
            scrollContent: {
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
                        
//                        Color.clear  // Add extra space to the bottom of the view
//                            .frame(height: 50)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
                
            }, stickyHeader: {
                self.stickyHeader
            })
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
        .ignoresSafeArea(edges: .bottom)
        //.orientationLock(.all)
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .background(Color.c1_background)
        .displayToast(self.$favoritesViewModel.toast)
    }
}

struct SelectModeBottomHeader: View {
    @EnvironmentObject private var favoritesViewModel: FavoriteViewModel
    
    @Binding var isSelectModeActive: Bool
    @State private var isSelectAll: Bool = false

    private var selectedCount: Int {
        self.favoritesViewModel.favoritesList.filter { $0.select == .checked }.count
    }
    
    var body: some View {
        HStack(alignment: .center) {
            BottomHeader.BottomHeaderButton {
                SelectBottomButton(label: self.isSelectAll ? "Deselect" : "Select All", system_name:"scope") {
                    withAnimation(.easeOut(duration: 0.25)) {
                        if self.isSelectAll {
                            self.favoritesViewModel.unSelectAll()
                        } else {
                            self.favoritesViewModel.favoritesList = self.favoritesViewModel.favoritesList.map { element in
                                var selectedElement = element
                                selectedElement.select = .checked
                                return selectedElement
                            }
                        }
                        
                        self.isSelectAll.toggle()
                    }
                }
            }
            
            BottomHeader.BottomHeaderButton {
                SelectBottomButton(label: "Remove", system_name:"heart.slash") {
                    withAnimation(.easeOut(duration: 0.25)) {
                        try? self.favoritesViewModel.unFavoriteSelected()
                        self.isSelectAll = false
                        
                        if self.favoritesViewModel.favoritesList.isEmpty {
                            self.isSelectModeActive = false
                        }
                    }
                }
                .opacity(self.selectedCount == 0 ? 0.35 : 1)
                .disabled(self.selectedCount == 0)
            }
            
            BottomHeader.BottomHeaderButton {
                SelectBottomButton(label: "Export", system_name:"square.and.arrow.up") {
                    Task {
                        await favoritesViewModel.exportSelectedMediaToPhotos()
                        self.favoritesViewModel.unSelectAll()
                        
                        self.isSelectModeActive = false
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical,10)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.c1_secondary)
        .onChange(of: self.isSelectModeActive) {
            if !self.isSelectModeActive {
                self.isSelectAll = false
            }
        }
    }
}
