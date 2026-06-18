//
//  AddBookmarkSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import SwiftUI

struct AddBookmarkSheet: View {
    @Environment(\.dismiss) var dismiss

    var webViewModel: WebViewModel
    var folderBookmarkViewModel: FolderBookmarkViewModel

    @State private var userTitle: String = ""
    @State private var faviconData: Data?
    @State private var toast: ToastItem?
    @State private var selectedFolder: FolderEntity?

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // Header
                    HStack {
                        Button {
                            self.dismiss()
                        } label: {
                            Text("X")
                                .font(.system(size: 20, design: .rounded))
                                .padding(15)
                                .foregroundStyle(.red)
                        }
                        .applyLiquidGlassIfSupported(shape: .circle)

                        Spacer()

                        Button {
                            if webViewModel.currentUrl == nil {
                                self.toast = ToastItem(message: "Url can not be empty", status: .failure)
                                return
                            }
                            if webViewModel.url == nil {
                                self.toast = ToastItem(message: "Url can not be empty", status: .failure)
                                return
                            }

                            let urlToSave = webViewModel.currentUrl

                            self.toast = self.folderBookmarkViewModel.addBookmark(
                                folder: self.selectedFolder,
                                url: urlToSave,
                                favicon: faviconData,
                                title: self.userTitle
                            )

                            self.dismiss()
                        } label: {
                            Text("Save")
                                .font(.system(size: 20, design: .rounded))
                                .padding(10)
                                .foregroundStyle(Color.c1_text)
                        }
                        .applyLiquidGlassIfSupported()
                    }
                    .overlay(alignment: .center) {
                        Text("Add Bookmark")
                            .font(.system(size: 20,weight: .semibold,design: .rounded))
                            .foregroundStyle(Color.c1_text)
                    }

                    // Display favicon, title (text field), link (view only)
                    HStack(spacing: 15) {
                        Group {
                            if let faviconData, let uiImage = UIImage(data: faviconData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 65,height: 65)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            } else {
                                Image(systemName: "globe.fill")
                                    .resizable()
                                    .frame(width: 55,height: 55)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                        }
                        .foregroundStyle(Color.c1_text)

                        VStack {
                            HStack {
                                TextField(
                                    "",
                                    text: $userTitle,
                                    prompt: Text("Enter title here...").foregroundStyle(Color.c1_text)
                                )
                                .focused($isFocused)
                                .foregroundStyle(Color.c1_text)
                                .font(.system(size: 16,design: .rounded))

                                if self.isFocused {
                                    Button {
                                        self.userTitle = ""
                                    } label: {
                                        Image(systemName: "x.circle.fill")
                                    }
                                }
                            }
                            .padding(.bottom,2)

                            Divider().background(Color.c1_text.opacity(0.5))

                            Text(self.webViewModel.currentUrl?.absoluteString ?? "Url not found")
                                .font(.system(size: 15,design: .rounded))
                                .opacity(0.75)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color.c1_text)
                                .lineLimit(1)
                                .padding(.top,2)
                        }
                    }
                    .padding(15)
                    .background(RoundedRectangle(cornerRadius: 25).foregroundStyle(Color.c1_accent))

                    // List of folders to add to
                    Section {
                        List {
                            Button {
                                self.selectedFolder = nil
                            } label: {
                                HStack {
                                    Label {
                                        Text("None")
                                            .foregroundStyle(Color.c1_text)
                                    } icon: {
                                        Image(systemName: "xmark")
                                            .foregroundStyle(Color.c1_text)
                                    }

                                    Spacer()

                                    if self.selectedFolder == nil {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.c1_text)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)

                            ForEach(self.folderBookmarkViewModel.folders) { folder in
                                Button {
                                    self.selectedFolder = folder
                                } label: {
                                    HStack {
                                        Label {
                                            Text(folder.title)
                                                .foregroundStyle(Color.c1_text)
                                        } icon: {
                                            Image(systemName: "folder.fill")
                                                .foregroundStyle(Color.c1_text)
                                        }

                                        Spacer()

                                        if self.selectedFolder == folder {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color.c1_text)
                                        }
                                    }
                                }
                                .listRowBackground(Color.clear)
                            }

                            NavigationLink {
                                CreateFolderSheet(folderBookmarkViewModel: self.folderBookmarkViewModel, toast: self.$toast)
                            } label: {
                                Label {
                                    Text("New Folder")
                                        .foregroundStyle(Color.c1_text)
                                } icon: {
                                    Image(systemName: "plus")
                                        .foregroundStyle(Color.c1_text)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                        .frame(height: CGFloat(self.folderBookmarkViewModel.folders.count + 2) * 52)
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                        .scrollDisabled(true)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.c1_accent)
                        )
                    } header: {
                        Text("Select Folder")
                            .foregroundStyle(Color.c1_text)
                            .font(.system(size: 20,weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .presentationDragIndicator(.hidden)
                .task {
                    self.isFocused = true
                    self.faviconData = await self.webViewModel.fetchFaviconData()
                    self.userTitle = self.webViewModel.webView?.title ?? webViewModel.webView?.url?.host ?? ""
                }
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .top)
            .background(Color.c1_background)
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast.message)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(toast.status == .failure ? Color.red.opacity(0.75) : Color.c1_accent.opacity(0.75))
                        .clipShape(Capsule())
                        .padding(.bottom, 15)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { self.toast = nil }
                            }
                        }
                }
            }
        }
    }
}
