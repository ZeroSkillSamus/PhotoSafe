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
        //.ignoresSafeArea(.keyboard) // Prevents keyboard pushing tab bar up
        NavigationStack(path: self.$path) {
            VStack(spacing:0) {
                TabView(selection: self.$current_tab) {
                    AlbumView(path: self.$path)
                        .environmentObject(self.album_VM)
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

                //if !self.toggle_plus_mode {
                    //Custom Tab Bar
                    VStack(spacing:0) {
                        
                        HStack(spacing:0) {
                            //Tab Buttons...
                            TabButton(tab:.albums,image: "rectangle.stack.fill")
                            
                            TabButton(tab:.favorites,image: "heart.fill")
                            
                            Button {
                                withAnimation(.easeIn) {
                                    self.toggle_plus_mode.toggle()
                                }
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
                    .opacity(self.toggle_plus_mode ? 0 : 1)
                //}
               // }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 20) {
                    HStack(spacing: 25) {
                        Button {
                            print("Import time")
                        } label: {
                            VStack {
                                ZStack {
                                    Circle().fill(.blue)
                                    Image(systemName: "photo.badge.plus")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 60,height: 60)
                                
                                Text("Import Photos")
                                    .foregroundStyle(.white)
                                    .font(.caption.bold())
                                    .frame(width: 50)
                            }
                        }
                        
                        Button {
                            self.display_sheet.toggle()
                        } label: {
                            VStack {
                                ZStack {
                                    Circle().fill(.blue)
                                    Image(systemName: "rectangle.stack.fill.badge.plus")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 60,height: 60)
                                
                                Text("New Album")
                                    .foregroundStyle(.white)
                                    .font(.caption.bold())
                                    .frame(width: 50)
                            }
                        }
                    }
                    
                    Button {
                        withAnimation(.easeInOut) {
                            self.toggle_plus_mode.toggle()
                        }
                        
                    } label: {
                        ZStack {
                            Circle().fill(.red)
                            Text("X")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                        }
                        .frame(width: 60,height: 60)
                    }
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .bottom)
                .background(.blue.opacity(0.75))
                .opacity(self.toggle_plus_mode ? 1 : 0)
                .onTapGesture {
                    withAnimation {
                        self.toggle_plus_mode.toggle()
                    }
                }
            }
            .sheet(isPresented: self.$display_sheet) {
                CreateAlbumSheet(album_vm: self.album_VM)
            }
            .navigationDestination(for: AlbumEntity.self) { album in
                MediaView(album: album)
            }
        }
        .background(self.toggle_plus_mode ? .black.opacity(0.25) : .clear)
    }
}
