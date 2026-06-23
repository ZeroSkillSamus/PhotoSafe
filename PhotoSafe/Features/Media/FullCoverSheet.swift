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

enum FavoriteStatus: String {
    case Like = "like"
    case Unlike = "unlike"
}

struct FullCoverSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    @EnvironmentObject private var slideShowViewModel: SlideShowViewModel
    
    // MARK: - Constants130597
    private let windowSize = 9
    
    @State private var currentMediaId: UUID?
    @State private var sheetOpacity: CGFloat = 0
    @State private var userTapped: Bool = false
    
    // Sheets to toggle
    //@State private var showAutoScrollerSheet: Bool = false
    @State private var displayMoveSheet: Bool = false
    
    // Variables needed for list
    @State private var windowListIndex: Int = 0 // Only used by LazyPagerView
    @State private var windowList: [SelectMediaEntity] = []
    
    // MARK: - Passed in vars
    var screenType: ScreenType
    @ObservedObject var mediaViewModel: MediaViewModel
    @Binding var mediaList: [SelectMediaEntity]
    var selecetedMedia: SelectMediaEntity
    
    // MARK: - Computed Variables
    var currentListIndex: Int? {
        mediaList.firstIndex { $0.id == currentMediaId }
    }
    
    var currentWindowListIndex: Int? {
        windowList.firstIndex { $0.id == currentMediaId }
    }
    
    var headerOpacity: Double {
        !self.userTapped ? 1 : 0
    }
    
    var isCurrentItemFavorited: Bool {
        guard let currentMediaId else { return false }
        return self.mediaList.first(where: { $0.id == currentMediaId })?.isFavorited ?? false
    }
    
    var body: some View {
        ZStack {
            LazyPagerView(
                windowedList: self.$windowList,
                windowListIndex: self.$windowListIndex,
                backgroundOpacity: self.$sheetOpacity,
                userTapped: self.$userTapped
            ).overlay(alignment: .top) {
                topHeader()
            }.overlay(alignment: .bottom) {
                bottomHeader()
            }
            .displayToast(self.$mediaViewModel.toast)
        }
        .persistentSystemOverlays(.hidden)
        .background(.black.opacity(self.sheetOpacity))
        .background(ClearFullScreenBackground())
        .sheet(isPresented: self.$slideShowViewModel.showSettings) {
            OptionsView()
        }
        .onChange(of: self.mediaList.count, { oldValue, newValue in
            if newValue == 0 { self.dismiss() }
        })
        .onChange(of: self.slideShowViewModel.displaySlideshow, { oldValue, newValue in
            if newValue { self.dismiss() }
        })
        .onChange(of: self.windowListIndex, { oldValue, newValue in
            // If newIndex is still contained in windowList dont bother updating
            guard self.windowList.indices.contains(newValue) else { return }
            
            let currentItem = self.windowList[newValue]
            self.currentMediaId = currentItem.id
            
            // Store if we are at either edges
            let atLeftEdge = newValue == 0
            let atRightEdge = newValue == self.windowList.count - 1
            
            guard let first = self.windowList.first, let last = self.windowList.last else { return }
            
            let windowLowerIndex = self.mediaList.firstIndex(of: first) ?? 0
            let windowUpperIndex = self.mediaList.firstIndex(of: last) ?? 0
            
            let canShiftLeft = windowLowerIndex > 0
            let canShiftRight = windowUpperIndex < self.mediaList.count - 1
            
            // If we are at the leftEdge and are able to shift left just return
            // Same pattern check for atRightEdge & canShiftRight
            guard (atLeftEdge && canShiftLeft) || (atRightEdge && canShiftRight) else { return }
            guard let newIndex = self.currentListIndex else { return }
            updateWindowedList(currentIndex: newIndex)
            
            // With the windowList being set we need to ensure that our windowListIndex stays
            if let currentWindowListIndex {
                self.windowListIndex = currentWindowListIndex
            }
        })
        .onAppear {
            guard let startIndex = self.mediaList.firstIndex(where: {$0.id == selecetedMedia.id}) else {
                self.mediaViewModel.setToast(message: "Failed to load media sheet", status: .failure)
                
                self.dismiss()
                return
            }
            self.currentMediaId = self.mediaList[startIndex].id
            
            // Populate the windowlist
            updateWindowedList(currentIndex: startIndex)
            
            // Need to set the windowListIndex to currentListIndex
            guard let currentWindowListIndex else {
                self.mediaViewModel.setToast(message: "Failed to load media sheet", status: .failure)
                
                self.dismiss()
                return
            }
            self.windowListIndex = currentWindowListIndex
        }
    }
    
    private func bottomHeader() -> some View {
        HStack {
            if self.screenType == .Media {
                moveMediaButton()
                
                deleteMediaButton()
            }
            
            favoriteButton()
            
            exportMediaButton()
        }
        .frame(maxWidth: .infinity, maxHeight: 30, alignment: .topLeading)
        .padding(.horizontal)
        .background(Color.c1_secondary)
        .opacity(self.sheetOpacity)
        .opacity(self.headerOpacity)
    }

    private func topHeader() -> some View {
        HStack {
            Button {
                self.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(Color.c1_text)
                    .padding(10)
                    .applyLiquidGlassIfSupported(shape: .circle, color: Color.c1_accent, isInteractive: true)
            }
            Spacer()

            Button {
                self.slideShowViewModel.showSettings = true
            } label: {
                Image(systemName: "play")
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(Color.c1_text)
                    .padding(10)
                    .applyLiquidGlassIfSupported(shape: .circle, color: Color.c1_accent,isInteractive: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 45, maxHeight: 45, alignment: .topLeading)
        .overlay(alignment: .top) {
            if let currentListIndex {
                Text("\(currentListIndex + 1) of \(mediaList.count)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.c1_text)
                    .frame(maxWidth: .infinity,alignment: .center)
                    .padding(.top,5)
            }
        }
        .padding([.horizontal])
        .background(Color.c1_secondary)
        .opacity(self.sheetOpacity)
        .opacity(self.headerOpacity)
    }
    
    // MARK: - Bottom Header Buttons
    
    private func deleteMediaButton() -> some View {
        SelectBottomButton(label: "Delete", system_name: "trash") {
            withAnimation {
                do {
                    // Get current id to be deleted and hold onto currentListIndex
                    guard let currentMediaId, let currentListIndex else {
                        self.mediaViewModel.setToast(message: "Failed to delete media", status: .failure)
                        return
                    }
                    
                    try self.mediaViewModel.delete(mediaId: currentMediaId)
                    
                    adjustWindowSizeForMediaButtons(currentListIndex: currentListIndex)
                } catch (let error) {
                    self.mediaViewModel.setToast(message: error.localizedDescription, status: .failure)
                    print("Failed to delete: \(error.localizedDescription))")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func moveMediaButton() -> some View {
        SelectBottomButton(label: "Move", system_name: "rectangle.2.swap") {
            self.displayMoveSheet.toggle()
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: self.$displayMoveSheet) {
            let currAlbumName = self.selecetedMedia.albumName
            MoveSheet(curr_album_name: currAlbumName) { album in
                do {
                    // Get current id to be deleted and hold onto currentListIndex
                    guard let currentMediaId, let currentListIndex else {
                        self.mediaViewModel.setToast(message: "Failed to move media to \(album.name)", status: .failure)
                        return
                    }
                    
                    try self.mediaViewModel.move(to: album, selectedId: currentMediaId)
                    adjustWindowSizeForMediaButtons(currentListIndex: currentListIndex)
                } catch {
                    self.mediaViewModel.setToast(message: "Failed to move media to \(album.name)", status: .failure)
                    print("Failed to delete: \(error.localizedDescription))")
                }
                
            }
        }
    }
    
    private func favoriteButton() -> some View {
        SelectBottomButton(
            label: "Favorite",
            system_name: self.isCurrentItemFavorited ? "heart.fill" : "heart"
        ) {
            guard let currentListIndex else {
                self.mediaViewModel.setToast(message: "Failed to like/unlike media", status: .failure)
                return
            }
            
            let currMedia = self.mediaList[currentListIndex]
            let newStatus = currMedia.isFavorited ? FavoriteStatus.Unlike : FavoriteStatus.Like
            
            guard let newEntity = self.mediaViewModel.toggleFavorite(id: currMedia.id, status: newStatus) else {
                self.mediaViewModel.setToast(message: "Failed to \(newStatus.rawValue) media", status: .failure)
                return
            }
            
            self.mediaList[currentListIndex] = SelectMediaEntity(media: newEntity)
            
            self.favoriteViewModel.setFavorites()   // Refresh favorites
            // On favorites screen we have the unfavorited delete
            // In that case we need to adjustWindowSize
            if screenType == .Favorite {
                adjustWindowSizeForMediaButtons(currentListIndex: currentListIndex)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func exportMediaButton() -> some View {
        SelectBottomButton(label: "Export", system_name: "square.and.arrow.up") {
            Task {
                guard let currentListIndex else {
                    self.mediaViewModel.setToast(message: "Failed to export media", status: .failure)
                    return
                }
                let mediaToExport = self.mediaList[currentListIndex]
                
                await self.mediaViewModel.exportSingle(selected: mediaToExport)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper functions
    
    private func adjustWindowSizeForMediaButtons(currentListIndex: Int) {
        // self.mediaViewModel.delete and self.mediaViewModel.move modifies the array to delete so no longer needed here
        // Will not work on favorites screen
        if self.mediaList.isEmpty { return }    // Have an onChange to tracks if empty and auto dismiss
        
        // Compare current index being deleted with the new total list count
        // Take the min of the two
        // EX: curr = 5 total = 10 (after delete)
        //     Will set the index to 5 (ensure we stay at the same index instead of doing a -1)
        let newIndex = min(currentListIndex, self.mediaList.count - 1)
        self.currentMediaId = self.mediaList[newIndex].id
        self.updateWindowedList(currentIndex: newIndex)
    }
    
    private func updateWindowedList(currentIndex: Int) {
        let lowerBound = max(0, currentIndex - windowSize / 2)
        let upperBound = min(self.mediaList.count - 1, currentIndex + windowSize / 2)
        self.windowList = Array(self.mediaList[lowerBound...upperBound])
    }
    
}
