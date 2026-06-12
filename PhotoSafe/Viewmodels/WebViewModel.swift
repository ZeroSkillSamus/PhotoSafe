//
//  WebViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import Foundation
import WebKit

struct ImageURLItem: Identifiable {
    let id = UUID()
    let url: String
}

@Observable
class WebViewModel {
    private let defaultSearchEngine: String = "https://duckduckgo.com/?q="

    var pendingImageURL: ImageURLItem? = nil
    private(set) var sessionHistory: [DownloadMediaItem] = []

    var url: URL? = nil
    var currentUrl: URL? = nil
    var progress: Double = 0

    var isLoading: Bool = false
    var error: Error? = nil

    weak var webView: WKWebView?

    var canGoBack: Bool = false
    var canGoFoward: Bool = false

    var isNavigating: Bool = false

    func update(url: URL?) {
        self.error = nil
        self.currentUrl = nil
        self.url = url
    }

    func update(isLoading: Bool, error: Error? = nil, isNavigating: Bool? = nil) {
        self.isLoading = isLoading
        self.error = error
        if let isNavigating {
            self.isNavigating = isNavigating
        }
    }

    func updateNavigationState() {
        self.canGoBack = webView?.canGoBack ?? false
        self.canGoFoward = webView?.canGoForward ?? false
    }

    func appendToHistory(urlString: String, status: Status, album: AlbumEntity) {
        guard let url = URL(string: urlString) else { return }
        sessionHistory.append(DownloadMediaItem(
            url: urlString,
            status: status,
            downloadedAt: Date.now,
            albumDownloadedTo: album.name,
            domain: url.host()
        ))
    }

    func goBack() {
        if !canGoBack { return }
        webView?.goBack()
    }

    func goForward() {
        if !canGoFoward { return }
        webView?.goForward()
    }

    func refresh() {
        webView?.reload()
    }

    func clear() {
        webView?.load(URLRequest(url: URL(string: "about:blank")!))
        url = nil
        currentUrl = nil
        error = nil
        isLoading = false
        sessionHistory = []
    }

    func userNavigateTo(urlString: String) {
        updateNavigationState()
        self.error = nil

        var newUrl = urlString.lowercased().trimmingCharacters(in: .whitespaces)

        if !isUrl(urlString: newUrl) {
            guard let encodedQuery = newUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            newUrl = defaultSearchEngine + encodedQuery
        } else if !newUrl.hasPrefix("https://") {
            newUrl = "https://" + newUrl
        } else if newUrl.hasPrefix("http://") {
            newUrl = newUrl.replacingOccurrences(of: "http://", with: "https://")
        }

        self.update(url: URL(string: newUrl))

        guard let url = URL(string: newUrl) else { return }
        webView?.load(URLRequest(url: url))
    }

    func update(currentUrl url: URL?) {
        self.currentUrl = url
        self.updateNavigationState()
    }

    func load(_ webView: WKWebView) {
        guard let url else { return }
        webView.load(URLRequest(url: url))
        update(isLoading: true)
    }

    func isUrl(urlString: String) -> Bool {
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return true
        }
        return urlString.contains(".") && urlString.rangeOfCharacter(from: .whitespaces) == nil
    }

    @MainActor
    func fetchFaviconData() async -> Data? {
        guard let urlString = await fetchFaviconURL(),
              let url = URL(string: urlString) else { return nil }

        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200 else { return nil }

        return data
    }

    @MainActor
    private func fetchFaviconURL() async -> String? {
        guard let webView else { return nil }

        return await withCheckedContinuation { continuation in
            let js = """
            (function() {
                var links = document.querySelectorAll('link[rel~="icon"], link[rel~="shortcut icon"]');
                if (links.length > 0) return links[links.length - 1].href;
                return window.location.origin + '/favicon.ico';
            })()
            """
            webView.evaluateJavaScript(js) { result, _ in
                continuation.resume(returning: result as? String)
            }
        }
    }
}
