//
//  BookmarkShowView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import SwiftUI

struct BookmarkShowView: View {
    @State private var selectedFolder: FolderEntity?
    @State private var showDeleteAllAlert: Bool = false
    @State private var toast: ToastItem?
    @State private var bookmarksToShow: [BookmarkEntity] = []

    var folderBookmarkViewModel: FolderBookmarkViewModel
    var webViewModel: WebViewModel

    @FocusState.Binding var isInputFocused: Bool
    @Binding var isPresented: Bool

    @ViewBuilder
    func display(bookmark: BookmarkEntity) -> some View {
        HStack {
            if let image = bookmark.faviconImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 40,height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .frame(width: 40,height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }

            Text(bookmark.title ?? "")
                .foregroundStyle(Color.c1_text)
                .font(.system(size: 15, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        VStack(spacing: 15) {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        Button {
                            self.selectedFolder = nil
                            self.bookmarksToShow = self.folderBookmarkViewModel.fetchBookmarksNotInFolder()
                        } label: {
                            Text("None")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.c1_text)
                        }
                        .padding(9)
                        .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 15))
                        .scaleEffect(selectedFolder == nil ? 1 : 0.8)

                        ForEach(self.folderBookmarkViewModel.folders) { folder in
                            Button {
                                self.selectedFolder = folder
                                self.bookmarksToShow = self.folderBookmarkViewModel.fetchBookmarksIn(folder: folder)
                            } label: {
                                Text(folder.title)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.c1_text)
                            }
                            .padding(9)
                            .applyLiquidGlassIfSupported(shape: .rect(cornerRadius: 15))
                            .scaleEffect(selectedFolder == folder ? 1 : 0.8)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Folders")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.c1_text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        print("Create folder")
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, design: .rounded))
                            .foregroundStyle(Color.c1_text)
                            .padding(8)
                    }
                    .applyLiquidGlassIfSupported(shape: .circle)
                }
            }

            Section {
                if self.bookmarksToShow.isEmpty {
                    Text("No bookmarks yet. Navigate to a page and tap ••• to save it.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.c1_text)
                        .font(.system(size: 15, design: .rounded))
                        .padding(7)
                        .opacity(0.7)
                } else {
                    List(self.bookmarksToShow) { bookmark in
                        Button {
                            self.webViewModel.update(url: bookmark.url)
                            self.webViewModel.webView?.load(URLRequest(url: bookmark.url))
                            self.isInputFocused = false
                            self.isPresented = false
                        } label: {
                            display(bookmark: bookmark)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.c1_accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 4)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                self.toast = self.folderBookmarkViewModel.deleteBookmark(bookmark: bookmark)
                                if toast?.status == .success {
                                    self.bookmarksToShow.removeAll(where: { $0 == bookmark })
                                }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                // Bring up edit sheet
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .tint(Color.c1_accent)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.c1_background)
                    .listStyle(.plain)
                }
            } header: {
                HStack {
                    Text("Bookmarks")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.c1_text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        self.showDeleteAllAlert = true
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, design: .rounded))
                            .foregroundStyle(Color.red)
                            .padding(8)
                    }
                    .applyLiquidGlassIfSupported(shape: .circle)
                    .disabled(self.bookmarksToShow.isEmpty)
                    .opacity(self.bookmarksToShow.isEmpty ? 0.55 : 1)
                }
                .alert("Delete All Bookmarks Not In Folders?", isPresented: self.$showDeleteAllAlert) {
                    Button(role: .destructive) {
                        self.toast = self.folderBookmarkViewModel.deleteBatchOfBookmarks(in: selectedFolder)
                        if toast?.status == .success {
                            self.bookmarksToShow.removeAll()
                        }
                    } label: {
                        Text("Delete")
                    }

                    Button(role: .cancel) {
                        print("Cancelled")
                    } label: {
                        Text("Cancel")
                    }
                } message: {
                    Text("Are you sure you want to delete all? This cannot be undone.")
                }
            }
        }
        .animation(.easeInOut, value: selectedFolder)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color.c1_background)
        .onAppear {
            self.selectedFolder = nil
            self.bookmarksToShow = self.folderBookmarkViewModel.fetchBookmarksNotInFolder()
        }
    }
}
