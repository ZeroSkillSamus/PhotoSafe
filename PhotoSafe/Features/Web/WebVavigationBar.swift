//
//  WebVavigationBar.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import SwiftUI

struct WebVavigationBar: View {
    var webViewModel: WebViewModel
    var folderBookmarkViewModel: FolderBookmarkViewModel
    
    
    @State private var userInputText: String = ""
    @State private var userSubmitedText: String = ""
    
    @Binding var showHistorySheet: Bool
    @Binding var toast: ToastItem?
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Button {
                    webViewModel.goBack()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .opacity(!webViewModel.canGoBack ? 0.5 : 1)
                .foregroundStyle(Color.c1_accent)
                .disabled(!webViewModel.canGoBack)

                Button {
                    webViewModel.goForward()
                } label: {
                    Image(systemName: "chevron.forward")
                        
                }
                .opacity(!webViewModel.canGoFoward ? 0.5 : 1)
                .foregroundStyle(Color.c1_accent)
                .disabled(!webViewModel.canGoFoward)
                
            }
            .padding(10)
            .applyLiquidGlassIfSupported()
            
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
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            Menu {
                Button {
                    self.showHistorySheet.toggle()
                } label: {
                    Label("Saved this session", systemImage: "folder.fill")
                        .foregroundStyle(Color.c1_accent)
                }
                
                Button {
                    Task {
                        if webViewModel.currentUrl == nil  {
                            self.toast = ToastItem(message: "Url can not be empty", status: .failure)
                            return
                        }
                        if webViewModel.url == nil  {
                            self.toast = ToastItem(message: "Url can not be empty", status: .failure)
                            return
                        }
                        
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
                    Label("Add to bookmarks", systemImage: "book.fill")
                }
                .foregroundStyle(Color.c1_accent)
                
            } label: {
                Image(systemName: "ellipsis")
                    .padding(10) // Establishes clean sizing container bounds natively
            }
            .foregroundStyle(Color.c1_accent)
            .applyLiquidGlassIfSupported() // Safely applies the effect without changing view structural identity

        }
        .frame(height:24)
        .padding(.horizontal)
        .padding(.vertical,10)
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
    }
}

extension View {
    @ViewBuilder
    func applyLiquidGlassIfSupported(shape: any Shape = .capsule) -> some View {
        if #available(iOS 26.0, *) {
            self
                .contentShape(shape)
                .glassEffect(.regular, in: shape)
        } else {
            // Safe pre-iOS 26 structural fallback layout
            self
                .contentShape(Capsule())
        }
    }
}
