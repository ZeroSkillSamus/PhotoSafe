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
    private struct FullCoverUIState {
        var orientation = UIDeviceOrientation.unknown
        var prev_orientation = UIDeviceOrientation.unknown
        var current_media_index = 0
        var display_move_sheet = false
        var did_user_tap = false
        var opacity: CGFloat = 0
        var did_export = false
        var windowListIndex: Int = 0
        
        // Computed properties work too
        var should_header_display: Bool {
            orientation.isPortrait || (orientation.isFlat && !prev_orientation.isLandscape) || orientation == .unknown
        }
        
        mutating func delete_from_current_media_index(count: Int) {
            if self.current_media_index == count - 1 && self.current_media_index != 0 {
                self.current_media_index -= 1
            }
        }
    }

    private let windowSize = 9

    private func updateWindowedList(currentIndex: Int) {
        let lowerBound = max(0, currentIndex - windowSize / 2)
        let upperBound = min(list.count - 1, currentIndex + windowSize / 2)
        windowedList = Array(list[lowerBound...upperBound])
    }

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var favorite_VM: FavoriteViewModel
    @EnvironmentObject private var slideShowViewModel: SlideShowViewModel
    
    @State private var videoToDisplay: SelectMediaEntity? = nil
    @State private var windowedList: [SelectMediaEntity] = []
    @State private var showAutoScrollerSheet: Bool = false 

    var from_where: ScreenType
    @ObservedObject var media_VM: MediaViewModel

    var select_media: SelectMediaEntity
    @Binding var list: [SelectMediaEntity]
   
    @State private var uiState = FullCoverUIState()

    private func delete_button() -> some View {
        SelectBottomButton(label: "Delete", system_name: "trash") {
            withAnimation {
                self.list[self.uiState.current_media_index].select = .checked
                self.uiState.delete_from_current_media_index(count: self.list.count)
                self.media_VM.delete_selected()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func move_button() -> some View {
        SelectBottomButton(label: "Move", system_name: "rectangle.2.swap") {
            self.uiState.display_move_sheet.toggle()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func export_button() -> some View {
        return (
            SelectBottomButton(label: "Export", system_name: "square.and.arrow.up") {
                let selected_media = self.list[self.uiState.current_media_index]
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
        SelectBottomButton(
            label: "Favorite",
            system_name: list[self.uiState.current_media_index].media.is_favorited ? "heart.fill" : "heart") {
            let prev_status = self.list[self.uiState.current_media_index].media.is_favorited
            let change_to = prev_status ? false : true // False means dislike, true means like
            
            // Get updated media and overwrite current element in list
            let new_media = self.media_VM.favorite_media(for: list[self.uiState.current_media_index].media, with: change_to)
            
            self.list[self.uiState.current_media_index] = SelectMediaEntity(media: new_media)
            
            // Update Favorites List
            if self.from_where == .Favorite {
                self.uiState.delete_from_current_media_index(count: self.list.count)
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
            
            if list.indices.contains(self.uiState.current_media_index) {
                favorite_button()
            }
            
            if from_where == .Media {
                delete_button()
            }
        }
        .padding(.horizontal)
        .background(Color.c1_secondary)
        .opacity(self.uiState.opacity)
        .opacity(!self.uiState.did_user_tap ? 1 : 0)
    }
    
    private func top_header() -> some View {
        HStack {
            Button {
                self.dismiss()
            } label: {
                ImageCircleOverlay(
                    color: Color.red,
                    icon: ImageCircleOverlay.IconType.text("X"),
                    frame: CGSize(width: 28, height: 28),
                    iconFont: .footnote
                )
            }
            Spacer()
            
            Button {
                // Show sheet to configire & start auto scroller
                self.showAutoScrollerSheet = true
            } label: {
                ImageCircleOverlay(
                    color: Color.c1_accent,
                    icon: ImageCircleOverlay.IconType.symbol("play.rectangle.fill"),
                    frame: CGSize(width: 28, height: 28),
                    iconFont: .footnote
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 40,alignment: .topLeading)
        .padding(.horizontal)
        .overlay(alignment: .top) {
            Text("\(self.uiState.current_media_index + 1) of \(list.count)")
                .font(.title3)
                .foregroundStyle(.primary)
        }
        .background(Color.c1_secondary)
        .opacity(self.uiState.opacity)
        .opacity(!self.uiState.did_user_tap ? 1 : 0)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if self.uiState.should_header_display || !self.uiState.did_user_tap {
                    top_header()
                }
 
                LazyPagerView(
                    windowedList: self.$windowedList,
                    windowListIndex: self.$uiState.windowListIndex,
                    backgroundOpacity: self.$uiState.opacity,
                    userTapped: self.$uiState.did_user_tap
                )
                
                // Shows Bottom Header
                if self.uiState.should_header_display || !self.uiState.did_user_tap {
                    bottom_header()
                }
            }
            .onRotate { newOrientation in
                self.uiState.prev_orientation = self.uiState.orientation
                self.uiState.orientation = newOrientation
            }
        }
        .onAppear {
            self.uiState.current_media_index = self.list.firstIndex(of: self.select_media) ?? 0
            updateWindowedList(currentIndex: uiState.current_media_index)
            self.uiState.windowListIndex = self.windowedList.firstIndex(of: self.select_media) ?? 0
        }
        .overlay(alignment: .center) {
            if self.media_VM.export_finished {
                CustomAlertView {
                    Text("Save Finished")
                        .font(.title3.bold())
                }
            }
        }
        .onChange(of: uiState.windowListIndex) { _, new_index in
            guard windowedList.indices.contains(new_index) else { return }

            let currentItem = windowedList[new_index]
            let newListIndex = list.firstIndex(of: currentItem) ?? 0
            self.uiState.current_media_index = newListIndex

            let atLeftEdge = new_index == 0
            let atRightEdge = new_index == windowedList.count - 1

            let windowLower = list.firstIndex(of: windowedList.first!) ?? 0
            let windowUpper = list.firstIndex(of: windowedList.last!) ?? 0
            let canShiftLeft = windowLower > 0
            let canShiftRight = windowUpper < list.count - 1

            guard (atLeftEdge && canShiftLeft) || (atRightEdge && canShiftRight) else { return }

            updateWindowedList(currentIndex: newListIndex)
            if let fixedIndex = windowedList.firstIndex(where: { $0.media.id == currentItem.media.id }) {
                self.uiState.windowListIndex = fixedIndex
            }
        }
        .sheet(isPresented: self.$showAutoScrollerSheet) {
            OptionsView()
        }
        .sheet(isPresented: self.$uiState.display_move_sheet) {
            MoveSheet(curr_album_name: self.select_media.media.album.name) { album in
                self.list[self.uiState.current_media_index].select = .checked
                self.uiState.delete_from_current_media_index(count: self.list.count)
                self.media_VM.move_selected(to: album)
                
                if self.list.isEmpty { self.dismiss() }
            }
        }
        .onChange(of: self.slideShowViewModel.displaySlideshow, { oldValue, newValue in
            if newValue == true {
                self.dismiss()
            }
        })
        .ignoresSafeArea(edges: !self.uiState.did_user_tap ? [] : [.bottom,.top])
        .persistentSystemOverlays(.hidden)
        .background(.black.opacity(self.uiState.opacity))
        .background(ClearFullScreenBackground())
    }
}
