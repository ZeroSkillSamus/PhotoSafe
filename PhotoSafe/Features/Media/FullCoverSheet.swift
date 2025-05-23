//
//  FullCoverSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI
import AVKit
import SDWebImageSwiftUI
import LazyPager

enum ScreenType {
    case Favorite
    case Media
}

struct FullCoverSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var favorite_VM: FavoriteViewModel
    
    var from_where: ScreenType
    @ObservedObject var media_VM: MediaViewModel
    
    var select_media: SelectMediaEntity
    @Binding var list: [SelectMediaEntity]
   
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var prev_orientation = UIDeviceOrientation.unknown
    
    @State private var current_media_index: Int = 0
    @State private var curr_media: SelectMediaEntity?
    @State private var display_move_sheet: Bool = false
    @State private var did_user_tap: Bool = false
    @State private var opacity: CGFloat = 0
    @State private var did_export: Bool = false
    
    var should_header_display: Bool {
        self.orientation.isPortrait || (self.orientation.isFlat && !self.prev_orientation.isLandscape) || self.orientation == .unknown
    }

    private func delete_button() -> some View {
        SelectBottomButton(label: "Delete", system_name: "trash") {
            withAnimation {
                self.list[self.current_media_index].select = .checked
                if self.current_media_index == self.list.count - 1 && self.current_media_index != 0 {
                    self.current_media_index -= 1
                }
                self.media_VM.delete_selected()
            }
            if self.list.isEmpty { self.dismiss() }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func image_view(_ ui_image: UIImage) -> some View {
        Image(uiImage: ui_image)
            .resizable()
            .scaledToFit()
    }
    
    private func move_button() -> some View {
        SelectBottomButton(label: "Move", system_name: "rectangle.2.swap") {
            self.display_move_sheet.toggle()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func export_button() -> some View {
        return (
            SelectBottomButton(label: "Export", system_name: "square.and.arrow.up") {
                let selected_media = self.list[self.current_media_index]
                self.media_VM.export_media_to_library(selected: selected_media)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.media_VM.export_finished = false
                    }
                }
            }
            .frame(maxWidth: .infinity)
        )
    }
    
    private func favorite_button() -> some View {
        SelectBottomButton(label: "Favorite", system_name: list[self.current_media_index].media.is_favorited ? "heart.fill" : "heart") {
            let prev_status = self.list[self.current_media_index].media.is_favorited
            let change_to = prev_status ? false : true // False means dislike, true means like
            
            // Get updated media and overwrite current element in list
            let new_media = self.media_VM.favorite_media(for: list[self.current_media_index].media, with: change_to)
            
            self.list[self.current_media_index] = SelectMediaEntity(media: new_media)
            
            // Update Favorites List
            if self.from_where == .Favorite {
                if self.current_media_index == self.list.count - 1 && self.current_media_index != 0 {
                    self.current_media_index -= 1
                }
            }
            
            self.favorite_VM.add_or_delete_from_favorites(for: new_media)
            
            if self.from_where == .Favorite && self.list.isEmpty {
                self.dismiss()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func bottom_header() -> some View {
        HStack {
            export_button()
            
            if from_where == .Media {
                move_button()
            }
            
            if list.indices.contains(self.current_media_index) {
                favorite_button()
            }
            
            if from_where == .Media {
                delete_button()
            }
        }
        .padding(.horizontal)
        .background(Color.c1_secondary)
        .opacity(self.opacity)
        .opacity(!self.did_user_tap ? 1 : 0)
    }
    
    private func top_header() -> some View {
        HStack {
            Button {
                self.dismiss()
            } label: {
                Image(systemName: "x.circle")
                    .font(.title3)
            }
            .foregroundStyle(.red)
            
            Spacer()
            
            Button {
                print("Edit")
            } label: {
                Text("Edit")
            }
            .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: 40,alignment: .topLeading)
        .padding(.horizontal)
        .overlay(alignment: .top) {
            Text("\(current_media_index + 1) of \(list.count)")
                .font(.title3)
                .padding(5)
                .foregroundStyle(.primary)
        }
        .background(Color.c1_secondary)
        .opacity(self.opacity)
        .opacity(!self.did_user_tap ? 1 : 0)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if should_header_display || !self.did_user_tap {
                    top_header()
                }
 
                LazyPager(data: self.list, page: self.$current_media_index) { element in
                    VStack {
                        switch element.media.type {
                        case MediaType.Photo.rawValue:
                            if let cached_image = ImageCache.fetch_image(for: element.media.id.uuidString) {
                                image_view(cached_image)
                            } else if let ui_image = ImageCache.set_image_and_return(for: element.media) {
                                image_view(ui_image)
                            }
                        case MediaType.Video.rawValue:
                            if let video_path = element.media.video_path, let url = URL(string: video_path) {
                                //if self.current_media_index == elment. { // Needed to stop video from preloading
                                if list[self.current_media_index] == element {
                                    PlayerView(
                                        did_user_tap: self.$did_user_tap,
                                        curr_orientation: self.orientation,
                                        prev_orientation: self.prev_orientation,
                                        url: url
                                    )
                                }
                            }
                        case MediaType.GIF.rawValue:
                            AnimatedImage(data: element.media.image_data)
                                .resizable()
                                .customLoopCount(0)
                                .scaledToFit()
                        default:
                            EmptyView()
                        }
                        
                    }
                }
                // Make the content zoomable
                .zoomable(min: 1, max: 5)
                .onDismiss(backgroundOpacity: $opacity) {
                    self.dismiss()
                }
                .onTap {
                    withAnimation {
                        self.did_user_tap.toggle()
                    }
                }
                .opacity(self.opacity)
                .frame(maxWidth:.infinity,maxHeight: .infinity)
                .ignoresSafeArea(edges: [.bottom, .top])
                
                // Shows Bottom Header
                if should_header_display || !self.did_user_tap {
                    bottom_header()
                }
            }
            .onRotate { newOrientation in
                self.prev_orientation = self.orientation
                self.orientation = newOrientation
            }
        }
        .onAppear {
            self.current_media_index = self.list.firstIndex(of: self.select_media) ?? 0
        }
        .overlay(alignment: .center) {
            if self.media_VM.export_finished {
                CustomAlertView {
                    Text("Save Finished")
                        .font(.title3.bold())
                }
            }
        }
        .sheet(isPresented: self.$display_move_sheet) {
            MoveSheet(curr_album_name: self.select_media.media.album.name) { album in
                self.list[self.current_media_index].select = .checked
                if self.current_media_index == self.list.count - 1 && self.current_media_index != 0 {
                    self.current_media_index -= 1
                }
                self.media_VM.move_selected(to: album)
                
                if self.list.isEmpty { self.dismiss() }
            }
        }
        .ignoresSafeArea(edges: !self.did_user_tap ? [] : [.bottom,.top])
        .persistentSystemOverlays(.hidden)
        .background(.black.opacity(opacity))
        .background(ClearFullScreenBackground())
    }
}
