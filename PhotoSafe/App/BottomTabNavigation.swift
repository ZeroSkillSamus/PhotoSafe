//
//  TabView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct ContentView: View {
    enum Tab: String {
        case favorites = "Favorites"
        case albums = "Albums"
        case web = "Web"
        case settings = "Settings"
    }
    
    @StateObject private var album_VM: AlbumViewModel = AlbumViewModel()
  
    @State private var current_tab: Tab = .albums // Current Tab
    @State private var path = NavigationPath()  // For NavigationStack
    
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

    var body: some View {
        //.ignoresSafeArea(.keyboard) // Prevents keyboard pushing tab bar up
        NavigationStack(path: self.$path) {
            VStack(spacing:0) {
                TabView(selection: self.$current_tab) {
                    AlbumView(path: self.$path)
                        .environmentObject(self.album_VM)
                        .tag(Tab.albums)
                        .toolbar(.hidden, for: .bottomBar)
                        .navigationBarTitleDisplayMode(.inline)
                    
                    Web()
                        .tag(Tab.web)
                    
                    Settings()
                        .tag(Tab.settings)
                    
                    Favorites()
                        .tag(Tab.favorites)
                }
                
                //Custom Tab Bar
                VStack(spacing:0) {
                    HStack(spacing:0) {
                        //Tab Buttons...
                        TabButton(tab:.albums,image: "rectangle.stack.fill")
                      
                        TabButton(tab:.favorites,image: "heart.fill")
                
                        Button {
                            print("hi")
                        } label: {
                            ZStack {
                                Circle().fill(.blue)
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 70,height: 70)
                        }
                        .offset(y: -5)

                        TabButton(tab:.web,image: "network")
                        
                        TabButton(tab:.settings,image: "gear")
                    }
                    .frame(maxWidth: .infinity,maxHeight: 55)
                }
                .background(.bar)
            }
            .navigationDestination(for: AlbumEntity.self) { album in
                MediaView(album: album)
            }
        }
    }
}
