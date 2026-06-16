//
//  WebVavigationBar.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import SwiftUI

struct CreateFolderSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var folderBookmarkViewModel: FolderBookmarkViewModel
    @Binding var toast: ToastItem?
    
    @FocusState private var isFocused: Bool
    @State private var userTitle: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
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
                        toast = folderBookmarkViewModel.addFolder(name: self.userTitle)
                        self.dismiss()
                    } label: {
                        Text("Create")
                            .font(.system(size: 20, design: .rounded))
                            .padding(10)
                            .foregroundStyle(Color.c1_text)
                    }
                    .applyLiquidGlassIfSupported()
                }
                .overlay(alignment: .center) {
                    Text("Create Folder")
                        .font(.system(size: 20,weight: .semibold,design: .rounded))
                        .foregroundStyle(Color.c1_text)
                }
                
                HStack {
                    TextField(
                        "",
                        text: $userTitle,
                        prompt: Text("Enter Folder Name Here...").foregroundStyle(Color.c1_text) // Custom placeholder color
                    )
                    .focused($isFocused)
                    .foregroundStyle(Color.c1_text)
                    .font(.system(size: 16,design: .rounded))
    //                .onSubmit {
    //                    toast = folderBookmarkViewModel.addFolder(name: self.userTitle)
    //                }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 25).foregroundStyle(Color.c1_accent))
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding()
        .background(Color.c1_background)
        .task {
            self.isFocused = true
        }
    }
}

struct WebVavigationBar: View {
    var webViewModel: WebViewModel
    var folderBookmarkViewModel: FolderBookmarkViewModel
    @Binding var isPresented: Bool
    
    @State private var userInputText: String = ""
    @State private var userSubmitedText: String = ""
    @State private var showAddBookmarkSheet: Bool = false
    
    @Binding var showHistorySheet: Bool
    @Binding var toast: ToastItem?
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack {
            if !isPresented {
                HStack {
                    Button {
                        webViewModel.goBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 20, design: .rounded))
                            .fontWeight(webViewModel.canGoBack ? .semibold : .regular)
                    }
                    .opacity(!webViewModel.canGoBack ? 0.5 : 1)
                    .foregroundStyle(Color.c1_accent)
                    .disabled(!webViewModel.canGoBack)
                    
                    Button {
                        webViewModel.goForward()
                    } label: {
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 20, design: .rounded))
                            .fontWeight(webViewModel.canGoFoward ? .bold : .regular)
                    }
                    .opacity(!webViewModel.canGoFoward ? 0.5 : 1)
                    .foregroundStyle(Color.c1_accent)
                    .disabled(!webViewModel.canGoFoward)
                }
                .padding(10)
                .applyLiquidGlassIfSupported()
            }
            
            TextField("Enter url here...", text: self.$userInputText)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .padding(6)
                .truncationMode(.middle)
                .background(Color.white.opacity(0.7))
                .cornerRadius(8)
                .foregroundStyle(Color.c1_accent)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    self.userSubmitedText = self.userInputText
                    self.webViewModel.update(url: URL(string: userSubmitedText))
                    self.webViewModel.userNavigateTo(urlString: userSubmitedText)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    self.isPresented = true
                })
                .frame(maxWidth: .infinity)

            Spacer()

            if isFocused {
                Button {
                    self.isFocused = false
                } label: {
                    Text("X")
                        .font(.system(size: 20, weight: .semibold,design: .rounded))
                        .padding(11)
                }
                .applyLiquidGlassIfSupported(shape: .circle)
                .foregroundStyle(Color.c1_accent)
            } else {
                Menu {
                    if webViewModel.currentUrl != nil {
                        Button {
                            Task {
                                let urlToSave = webViewModel.currentUrl
                                let title = webViewModel.webView?.title ?? webViewModel.webView?.url?.host ?? ""
                                let faviconData = await webViewModel.fetchFaviconData()

                                self.toast = folderBookmarkViewModel.addBookmark(
                                    folder: nil,
                                    url: urlToSave,
                                    favicon: faviconData,
                                    title: title
                                )
                            }
                        } label: {
                            Label("Add to Bookmarks", systemImage: "bookmark")
                        }
                        .foregroundStyle(Color.c1_accent)
                        
                        Button {
                            self.showAddBookmarkSheet.toggle()
                        } label: {
                            Label("Add Bookmark to...", systemImage: "book")
                        }
                        .foregroundStyle(Color.c1_accent)
                    }
                    
                    Divider()
                    
                    Button {
                        self.showHistorySheet.toggle()
                    } label: {
                        Label("Saved this session", systemImage: "folder")
                            .foregroundStyle(Color.c1_accent)
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, design: .rounded))
                        .padding(10)
                        .applyLiquidGlassIfSupported()
                }
                .foregroundStyle(Color.c1_accent)
            }
            
        }
        .frame(height: 30)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.c1_secondary)
        .onAppear {
            self.userInputText = self.webViewModel.currentUrl?.absoluteString ?? ""
        }
        .onChange(of: webViewModel.currentUrl) { oldValue, newValue in
            self.userInputText = newValue?.absoluteString ?? ""
        }
        .overlay(alignment: .bottom) {
            if webViewModel.isLoading {
                ProgressView(value: webViewModel.progress, total: 1.0)
                    .tint(Color.c1_primary)
            }
        }
        .animation(.easeInOut, value: self.isFocused)
        .sheet(isPresented: self.$showAddBookmarkSheet) {
            AddBookmarkSheet(webViewModel: self.webViewModel, folderBookmarkViewModel: self.folderBookmarkViewModel)
        }
    }
}
