//
//  FavoritesView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorite_VM: FavoriteViewModel
    @EnvironmentObject private var album_VM: AlbumViewModel
    @StateObject private var media_VM: MediaViewModel = MediaViewModel()
    
    var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 3), count: 4)
    @State private var selected_media: SelectMediaEntity?
    @State private var select_count: Int = 0
    
    @State private var show_slideshow_settings: Bool = false
    @State private var display_slideshow: Bool = false
    @State private var toggle_shuffle: Bool = false
    @State private var play_slides_auto: Bool = false
    @State private var display_horizontal_slide_show: Bool = false
    @State private var time_interval: TimeInterval = 2
//    @State private var current_media_index: Int = 0
//    @State private var sheet_media_index: Int = 0
//    @State private var display_move_sheet: Bool = false
//    @State private var export_finished: Bool = false
    
    @Binding var select_mode_active: Bool
    
    func leading_button() -> some View {
        Button {
            self.show_slideshow_settings.toggle()
        } label: {
            Image(systemName: "play.rectangle.fill")
                .font(.title2)
                .foregroundStyle(Color.c1_text)
        }

    }
    
    private func trailing_button() -> some View {
        Button {
            withAnimation(.easeInOut) {
                self.select_mode_active.toggle()
            }
        } label: {
            Text(self.select_mode_active ? "Cancel" : "Select")
        }
    }
    
    var header: Text {
        if self.select_mode_active {
            if self.select_count == 0 {
                return Text("Select Media")
            } else {
                return Text("^[\(self.select_count) Item](inflect: true) Selected")
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
                self.leading_button()
            } trailing_button: {
                self.trailing_button()
            }

            ScrollView {
                LazyVGrid(columns: self.gridItemLayout, spacing: 3) {
                    ForEach(self.$favorite_VM.favorites_list,id:\.self) { $favorite in
                        if let ui_image = favorite.media.thumbnail_image {
                            MediaImageGridView(
                                is_select_mode_active: self.select_mode_active,
                                ui_image: ui_image,
                                display_if_favorited: false,
                                media_select: $favorite,
                                selected_media: self.$selected_media,
                                select_count: self.$select_count
                            )
                        }
                    }
                }
            }
            
            if self.select_mode_active {
                Button {
                    self.favorite_VM.unselect_all()
                    self.select_count = 0
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
        .fullScreenCover(item: self.$selected_media) { element in
            FullCoverSheet(
                from_where: .Favorite,
                media_VM: MediaViewModel(),
                select_media: element,
                list: self.$favorite_VM.favorites_list
            )
        }
        .fullScreenCover(isPresented: self.$display_slideshow) {
            VerticalMediaVIew(
                list: self.favorite_VM.favorites_list,
                shuffle_list: self.$toggle_shuffle,
                time_interval: self.$time_interval,
                auto_slide_enabled: self.$play_slides_auto
            )
        }
        .sheet(isPresented: self.$show_slideshow_settings) {
            OptionsView(
                display_vertical_slide: self.$display_slideshow,
                display_horizontal_slide: self.$display_horizontal_slide_show,
                toggle_shuffle: self.$toggle_shuffle,
                play_slides_auto: self.$play_slides_auto,
                time_interval: self.$time_interval
            )
        }
        
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .background(Color.c1_background)
    }
}
