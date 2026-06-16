//
//  WebView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI
import WebKit

enum Status: String {
    case success
    case failure
}

struct ToastItem {
    let message: String
    let status: Status
}

struct DownloadMediaItem: Hashable {
    let url: String
    var status: Status
    var downloadedAt: Date
    var albumDownloadedTo: String
    var domain: String?

    var timeSinceCreated: Text {
        let today = Date()
        let components = Calendar.current.dateComponents([.day, .month, .hour, .year, .minute, .second, .weekday], from: today, to: downloadedAt)

        if let year = components.year, year < 0 {
            return Text(downloadedAt.formatted(date: .abbreviated, time: .shortened))
        } else if let month = components.month, month < 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return Text(formatter.string(from: downloadedAt))
        } else if let day = components.day, day < 0 {
            return Text("^[\(abs(day)) day](inflect: true) ago")
        } else if let hour = components.hour, hour < 0 {
            return Text("^[\(abs(hour)) hour](inflect: true) ago")
        } else if let minute = components.minute, minute < 0 {
            return Text("^[\(abs(minute)) min](inflect: true) ago")
        } else if let second = components.second, second < 0 {
            return Text("^[\(abs(second)) sec](inflect: true) ago")
        }
        return Text("")
    }
}

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
    func bookmarkShowView() -> some View {
        VStack(spacing: 15) {
            Section {
                Text("No folders yet. Tap + to create one or create one when saving a bookmark.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.c1_text)
                    .font(.system(size: 15, design: .rounded))
                    .padding(7)
                    .opacity(0.7)
            } header: {
                HStack {
                    Text("Folders")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
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
                if self.folderBookmarkViewModel.bookmarksNotInFolder.isEmpty {
                    Text("No bookmarks yet. Navigate to a page and tap ••• to save it.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.c1_text)
                        .font(.system(size: 15, design: .rounded))
                        .padding(7)
                        .opacity(0.7)
                } else {
                    List(self.folderBookmarkViewModel.bookmarksNotInFolder) { bookmark in
                        display(bookmark: bookmark)
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
                        self.toast = self.folderBookmarkViewModel.deleteAllBookmarksNotInFolder()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, design: .rounded))
                            .foregroundStyle(Color.red)
                            .padding(8)
                    }
                    .applyLiquidGlassIfSupported(shape: .circle)
                    .disabled(self.folderBookmarkViewModel.bookmarksNotInFolder.isEmpty)
                    .opacity(self.folderBookmarkViewModel.bookmarksNotInFolder.isEmpty ? 0.55 : 1)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.c1_background)
    }

    @ViewBuilder
    func display(bookmark: BookmarkEntity) -> some View {
        HStack {
            if let image = bookmark.faviconImage {
                Image(uiImage: image)
            } else {
                Image(systemName: "questionmark.circle")
            }

            Text(bookmark.title ?? "")
                .foregroundStyle(Color.c1_text)
                .font(.system(size: 15, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.c1_accent)
                .padding(.horizontal, 5)
                .padding(.vertical, 4)
        )
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
            WebVavigationBar(
                webViewModel: self.webViewModel,
                folderBookmarkViewModel: folderBookmarkViewModel,
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
                if isPresented { bookmarkShowView() }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented)
        .onChange(of: self.isInputFocused) { oldValue, newValue in
            self.isPresented = newValue
            if newValue {
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                }
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
                    .background(toast.status == .failure ? Color.red.opacity(0.85) : Color.c1_accent.opacity(0.75))
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

struct WebView: UIViewRepresentable {
    var webViewModel: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        let disableCallout = WKUserScript(
            source: "document.documentElement.style.webkitTouchCallout = 'none';",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(disableCallout)

        config.websiteDataStore = .nonPersistent()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all

        let longPressScript = WKUserScript(
            source: """
            (function() {
                var longPressTimer = null;
                var DURATION = 1000;

                function attachLongPress(img) {
                    img.addEventListener('touchstart', function(e) {
                        var src = img.src || img.currentSrc;
                        if (!src) return;
                        longPressTimer = setTimeout(function() {
                            window.webkit.messageHandlers.imageLongPress.postMessage({ src: src });
                        }, DURATION);
                    }, { passive: true });

                    img.addEventListener('touchend', function() { clearTimeout(longPressTimer); });
                    img.addEventListener('touchmove', function() { clearTimeout(longPressTimer); });
                }

                document.querySelectorAll('img').forEach(attachLongPress);

                new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                        mutation.addedNodes.forEach(function(node) {
                            if (node.nodeName === 'IMG') { attachLongPress(node); }
                            if (node.querySelectorAll) { node.querySelectorAll('img').forEach(attachLongPress); }
                        });
                    });
                }).observe(document.body, { childList: true, subtree: true });
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(longPressScript)
        config.userContentController.add(context.coordinator, name: "imageLongPress")

        let view = WKWebView(frame: .zero, configuration: config)


        view.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        view.addObserver(context.coordinator, forKeyPath: "URL", options: .new, context: nil)

        view.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"

        self.webViewModel.load(view)
        webViewModel.webView = view
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator

        return view
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "imageLongPress")
        uiView.removeObserver(coordinator, forKeyPath: "estimatedProgress")
        uiView.removeObserver(coordinator, forKeyPath: "URL")
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = webViewModel.url,
           uiView.url == nil,
           !webViewModel.isNavigating {
            self.webViewModel.load(uiView)
        }

        if uiView.url != webViewModel.currentUrl {
            webViewModel.update(currentUrl: uiView.url)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
        var parent: WebView

        init(parent: WebView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "imageLongPress",
                  let body = message.body as? [String: Any],
                  let src = body["src"] as? String else { return }
            parent.webViewModel.pendingImageURL = ImageURLItem(url: src)
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            guard let webView = object as? WKWebView else { return }
            if keyPath == "estimatedProgress" {
                parent.webViewModel.progress = webView.estimatedProgress
            } else if keyPath == "URL" {
                parent.webViewModel.update(currentUrl: webView.url)
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard navigationAction.navigationType == .linkActivated else {
                return nil
            }
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            let urlString = url.absoluteString

            if urlString.contains("x-safari-https://") {
                decisionHandler(.cancel)
                return
            }

            if let scheme = url.scheme?.lowercased(),
               scheme != "http" && scheme != "https" {
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.webViewModel.update(isLoading: false, isNavigating: false)
            parent.webViewModel.update(currentUrl: webView.url)


            let preventEscapeScript = """
            (function() {
                const originalAssign = window.location.assign;
                const originalReplace = window.location.replace;
                const originalOpen = window.open;

                window.location.assign = function(url) {
                    if (url && url.toString().includes('x-safari-https')) { return; }
                    return originalAssign.call(this, url);
                };

                window.location.replace = function(url) {
                    if (url && url.toString().includes('x-safari-https')) { return; }
                    return originalReplace.call(this, url);
                };

                window.open = function(url) {
                    if (url && url.toString().includes('x-safari-https')) { return null; }
                    return originalOpen.call(this, url);
                };

                document.addEventListener('click', function(e) {
                    let target = e.target.closest('a');
                    if (target && target.href && target.href.includes('x-safari-https')) {
                        e.preventDefault();
                        e.stopPropagation();
                        return false;
                    }
                }, true);
            })();
            """

            webView.evaluateJavaScript(preventEscapeScript, completionHandler: nil)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.webViewModel.update(isLoading: true)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {}

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
            if (error as NSError).code == NSURLErrorCancelled {
                parent.webViewModel.update(isLoading: false)
                parent.webViewModel.update(currentUrl: webView.url)
            } else if (error as NSError).domain == "WebKitErrorDomain" && (error as NSError).code == 102 {
                parent.webViewModel.update(isLoading: false)
            } else {
                parent.webViewModel.update(isLoading: false, error: error)
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code == NSURLErrorCancelled {
                parent.webViewModel.update(isLoading: false)
            } else if (error as NSError).domain == "WebKitErrorDomain" && (error as NSError).code == 102 {
                parent.webViewModel.update(isLoading: false)
            } else {
                parent.webViewModel.update(isLoading: false, error: error)
            }
            parent.webViewModel.update(currentUrl: parent.webViewModel.currentUrl)
        }
    }
}
