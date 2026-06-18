//
//  WebViewWrapper.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import SwiftUI

struct WebViewWrapper: View {
    @Environment(WebViewModel.self) var webViewModel
    @EnvironmentObject private var authViewModel: AuthStorageViewModel

    @State private var folderBookmarkViewModel = FolderBookmarkViewModel()
    @State private var isPresented: Bool = false
    @State private var toast: ToastItem? = nil
    @State private var showHistorySheet: Bool = false

    @FocusState private var isInputFocused: Bool

    @ViewBuilder
    func serverNotFoundView() -> some View {
        let error = webViewModel.error
        VStack(spacing: 15) {
            Image(systemName: "lock.shield.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.c1_primary)

            Text("Server not found")
                .font(.title3)
                .foregroundStyle(Color.c1_text)

            Text(error?.localizedDescription ?? "")
                .font(.caption)
                .foregroundStyle(Color.c1_text)

            Button {
                webViewModel.refresh()
            } label: {
                Text("Try Again")
            }
            .buttonBorderShape(.roundedRectangle)
            .foregroundStyle(Color.c1_accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.c1_background)
    }

    @ViewBuilder
    func defaultView() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .frame(width: 100, height: 120)
                .foregroundStyle(Color.c1_primary)

            VStack(spacing: 15) {
                Text("Browse privately, stay protected!")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.c1_accent)

                Text("Your activity stays yours. This browser leaves no history, stores no cookies, and clears everything when you leave. Links always open over HTTPS, and searches go through DuckDuckGo — a search engine that never tracks you.")
                    .foregroundStyle(Color.c1_primary)
                    .font(.system(size: 15, weight: .regular, design: .rounded))

                Text("What you browse here, stays here.")
                    .foregroundStyle(Color.c1_primary)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
        .background(Color.c1_background)
    }

    func displayMediaHistoryView() -> some View {
        VStack {
            Text("Saved This Session")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.c1_text)

            ScrollView {
                LazyVStack {
                    ForEach(self.webViewModel.sessionHistory, id: \.self) { item in
                        HStack(spacing: 15) {
                            AsyncImage(url: URL(string: item.url)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image.resizable()
                                        .frame(width: 85, height: 85)
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                case .failure:
                                    Text("Failure")
                                @unknown default:
                                    Text("Failure")
                                }
                            }

                            VStack {
                                Text(item.domain ?? "")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(item.albumDownloadedTo)
                                    .font(.system(size: 14, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .foregroundStyle(Color.c1_text)
                        }
                        .overlay(alignment: .topTrailing) {
                            item.timeSinceCreated
                                .font(.system(size: 12, design: .rounded))
                                .opacity(0.75)
                                .foregroundStyle(Color.c1_text)
                        }
                    }
                }
            }
        }
        .padding()
        .presentationDragIndicator(.visible)
        .background(Color.c1_background)
    }

    var body: some View {
        @Bindable var webViewModel = webViewModel

        VStack(spacing: 0) {
            WebNavigationBar(
                webViewModel: self.webViewModel,
                folderBookmarkViewModel: folderBookmarkViewModel,
                isPresented: self.$isPresented,
                showHistorySheet: self.$showHistorySheet,
                toast: self.$toast,
                isFocused: self.$isInputFocused
            )

            Group {
                if webViewModel.url != nil {
                    ZStack {
                        if webViewModel.error != nil {
                            serverNotFoundView()
                        } else {
                            WebView(webViewModel: webViewModel)
                        }
                    }
                } else {
                    defaultView()
                }
            }
            .overlay {
                if isPresented {
                    BookmarkShowView(
                        folderBookmarkViewModel: self.folderBookmarkViewModel,
                        webViewModel: self.webViewModel,
                        isInputFocused: self.$isInputFocused,
                        isPresented: self.$isPresented
                    )
                }
            }
        }
        .animation(.easeInOut, value: isPresented)
        .onChange(of: self.isInputFocused) { oldValue, newValue in
            if newValue {
                self.isPresented = true
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                }
            } else if !isPresented {
                self.isPresented = false
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: self.$showHistorySheet) {
            self.displayMediaHistoryView()
        }
        .sheet(item: $webViewModel.pendingImageURL) { item in
            MoveSheet { album in
                Task {
                    self.toast = await MediaViewModel().addPhotoFromWebToAlbum(from: item.url, to: album)
                    guard let toast else { return }
                    self.webViewModel.appendToHistory(urlString: item.url, status: toast.status, album: album)
                }
            }
        }
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
        .onChange(of: self.authViewModel.isUnlocked) { oldValue, newValue in
            if !newValue { self.isInputFocused = false }
        }
    }
}
