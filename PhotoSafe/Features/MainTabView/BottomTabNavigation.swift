//
//  TabView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct BottomTabNavigation: View {
    private let mediaService = MediaService()
    
    enum Tab: String {
        case favorites = "Favorites"
        case albums = "Albums"
        case web = "Web"
        case settings = "Settings"
    }
    
    @EnvironmentObject private var authViewModel: AuthStorageViewModel
    
    @StateObject private var album_VM: AlbumViewModel = AlbumViewModel()
    @StateObject private var favorite_VM: FavoriteViewModel = FavoriteViewModel()
    
    @State private var current_tab: Tab = .albums // Current Tab
    @State private var path = NavigationPath()  // For NavigationStack
    @State private var display_sheet: Bool = false
    @State private var toggle_plus_mode: Bool = false
    
    @State private var select_mode_active: Bool = false
    @State private var toast: ToastItem?
    
    @ViewBuilder
    private func TabButton(tab:Tab, image: String) -> some View {
        Button {
            withAnimation {
                self.current_tab = tab
            }
        } label: {
            VStack {
                Image(systemName: image)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width:23,height:22)
                Text(tab.rawValue)
                    .font(.caption2)
            }
            .foregroundStyle(self.current_tab == tab ? Color.c1_accent : Color.c1_background)
        }
        .frame(maxWidth: .infinity)
    }

    private func CustomNavHeader() -> some View {
        return (
            HStack(spacing:0) {
                //Tab Buttons...
                TabButton(tab:.albums,image: "rectangle.stack.fill")
                
                TabButton(tab:.favorites,image: "heart.fill")
                
                Button {
                    withAnimation(.easeIn) {
                        self.toggle_plus_mode.toggle()
                    }
                } label: {
                    ImageCircleOverlay()
                }
                .offset(y: -5)
                
                TabButton(tab:.web,image: "network")
                
                TabButton(tab:.settings,image: "gear")
            }
            .frame(maxWidth: .infinity,maxHeight: 55)
        )
    }
    
    private var shouldShowFavoriteSelectionBar: Bool {
        self.current_tab == .favorites && self.select_mode_active
    }
    
    var body: some View {
        // // Prevents keyboard pushing tab bar up
        NavigationStack(path: self.$path) {
            ZStack {
                VStack(spacing:0) {
                    TabView(selection: self.$current_tab) {
                        AlbumView(path: self.$path)
                            .tag(Tab.albums)
                            .toolbar(.hidden, for: .tabBar)
                            .background(Color.c1_background)
                        
                        WebViewWrapper()
                            .tag(Tab.web)
                            .toolbar(.hidden, for: .tabBar)
                            .background(Color.c1_background)
                        
                        SettingsView()
                            .tag(Tab.settings)
                            .toolbar(.hidden, for: .tabBar)
                            .background(Color.c1_background)
                        
                        
                        FavoritesView(isSelectModeActive: self.$select_mode_active)
                            .tag(Tab.favorites)
                            .toolbar(.hidden, for: .tabBar)
                            .background(Color.c1_background)
                            .ignoresSafeArea(edges: select_mode_active ? .bottom : [])
                    }
                    
                    //Custom Tab Bar
                    VStack(spacing:0) {
                        ZStack {
                            CustomNavHeader()
                                .background(Color.c1_secondary)
                                .opacity(self.toggle_plus_mode || self.shouldShowFavoriteSelectionBar ? 0 : 1)
                                .allowsHitTesting(!self.toggle_plus_mode && !self.shouldShowFavoriteSelectionBar)
                            
                            SelectModeBottomHeader(isSelectModeActive: self.$select_mode_active)
                                .opacity(self.shouldShowFavoriteSelectionBar ? 1 : 0)
                                .allowsHitTesting(self.shouldShowFavoriteSelectionBar)
                        }
                        .frame(height: 55)
                    }
                    .background(Color.c1_background)
                    .animation(.easeOut(duration: 0.25), value: toggle_plus_mode)
                    .animation(.easeOut(duration: 0.25), value: select_mode_active)
                }
            }
            .ignoresSafeArea(.keyboard)
            .overlay(alignment: .bottom) {
                PlusMode(toggle_plus_mode: self.$toggle_plus_mode)
            }
            .navigationDestination(for: AlbumEntity.self) { album in
                MediaView(album: album)
            }
        }
        .environmentObject(self.album_VM)
        .environmentObject(self.favorite_VM)
        .onAppear {
            self.favorite_VM.setFavorites()
        }
        .background(self.toggle_plus_mode ? Color.red.opacity(0.25) : Color.orange)
        .onChange(of: self.authViewModel.isUnlocked) { oldValue, newValue in
            guard !oldValue, newValue else { return }

            //MARK: - Needed to migrate from old method to new method
//            do {
//                let result = try mediaService.migrateVideoPathsToFilenames()
//
//                print("""
//                Video migration:
//                migrated: \(result.migrated)
//                current: \(result.alreadyCurrent)
//                missing: \(result.missing)
//                """)
//
//                // Refresh copied SelectMediaEntity values after migration.
//                favorite_VM.setFavorites()
//            } catch {
//                print("Video path migration failed: \(error)")
//            }

            current_tab = .albums
            path = NavigationPath()
        }
    }
}
