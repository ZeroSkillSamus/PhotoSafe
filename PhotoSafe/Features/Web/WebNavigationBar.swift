//
//  WebVavigationBar.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import SwiftUI

struct WebNavigationBar: View {
    var webViewModel: WebViewModel
    var folderBookmarkViewModel: FolderBookmarkViewModel
    @Binding var isPresented: Bool
    //@Binding var isInOverlayMode: Bool
    
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
                    .foregroundStyle(Color.c1_text)
                    .disabled(!webViewModel.canGoBack)
                    
                    Button {
                        webViewModel.goForward()
                    } label: {
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 20, design: .rounded))
                            .fontWeight(webViewModel.canGoFoward ? .bold : .regular)
                    }
                    .opacity(!webViewModel.canGoFoward ? 0.5 : 1)
                    .foregroundStyle(Color.c1_text)
                    .disabled(!webViewModel.canGoFoward)
                }
                .padding(10)
                .applyLiquidGlassIfSupported(color: Color.c1_accent)
            }
            
            TextField("Enter url here...", text: self.$userInputText)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .padding(6)
                .truncationMode(.middle)
                .background(Color.white.opacity(0.7))
                .cornerRadius(8)
                .foregroundStyle(Color.c1_background)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    self.userSubmitedText = self.userInputText
                    self.webViewModel.update(url: URL(string: userSubmitedText))
                    self.webViewModel.userNavigateTo(urlString: userSubmitedText)
                    
                    self.isFocused = false
                    self.isPresented = false
                }
                .simultaneousGesture(TapGesture().onEnded {
                    self.isFocused = true
                    self.isPresented = true
                })
                .frame(maxWidth: .infinity)

            Spacer()

            if self.isPresented {
                Button {
                    self.isFocused = false
                    self.isPresented = false
                } label: {
                    Text("X")
                        .font(.system(size: 20, weight: .semibold,design: .rounded))
                        .padding(11)
                        .foregroundStyle(Color.c1_text)
                }
                .applyLiquidGlassIfSupported(shape: .circle,color: Color.c1_accent)
                
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
                    
                    Button {
                        self.webViewModel.clearAllCookiesAndCache()
                    } label: {
                        Label("Clear history and cookies", systemImage: "document.on.trash")
                            .foregroundStyle(Color.c1_accent)
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, design: .rounded))
                        .padding(10)
                        .applyLiquidGlassIfSupported(color: Color.c1_accent)
                }
                .foregroundStyle(Color.c1_text)
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
