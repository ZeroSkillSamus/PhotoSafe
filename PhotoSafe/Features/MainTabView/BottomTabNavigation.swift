//
//  TabView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct BottomTabNavigation: View {
    enum Tab: String {
        case favorites = "Favorites"
        case albums = "Albums"
        case web = "Web"
        case settings = "Settings"
    }
    
    @StateObject private var album_VM: AlbumViewModel = AlbumViewModel()
  
    @State private var current_tab: Tab = .albums // Current Tab
    @State private var path = NavigationPath()  // For NavigationStack
    @State private var display_sheet: Bool = false
    @State private var toggle_plus_mode: Bool = false
    
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
            .foregroundColor(self.current_tab == tab ? .primary : .gray)

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
    
    var body: some View {
        // // Prevents keyboard pushing tab bar up
        NavigationStack(path: self.$path) {
            ZStack {
                VStack(spacing:0) {
                    TabView(selection: self.$current_tab) {
                        AlbumView(path: self.$path)
                            .tag(Tab.albums)
                            .toolbar(.hidden, for: .bottomBar)
                            .navigationBarTitleDisplayMode(.inline)
                        
                        WebView()
                            .tag(Tab.web)
                        
                        SettingsView()
                            .tag(Tab.settings)
                        
                        FavoritesView()
                            .tag(Tab.favorites)
                    }
                    
                    //Custom Tab Bar
                    VStack(spacing:0) {
                        CustomNavHeader()
                        
                    }
                    .background(.bar)
                    
                    .opacity(self.toggle_plus_mode ? 0 : 1)
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
        .background(self.toggle_plus_mode ? .black.opacity(0.25) : .clear)
    }
}
