//
//  WebViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import Foundation
import WebKit

enum WebMediaType: String {
    case image
    case video
}

struct ImageURLItem: Identifiable {
    let id = UUID()
    let url: String
    let mediaType: WebMediaType
}

@MainActor
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

    func clearAllCookiesAndCache() {
        // Clear legacy HTTPCookieStorage just in case
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        // Fetch and remove all types of website data (cookies, cache, localStorage, etc.)
        let dataStore = WKWebsiteDataStore.default()
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        dataStore.fetchDataRecords(ofTypes: allTypes) { records in
            dataStore.removeData(ofTypes: allTypes, for: records) {
                print("Successfully cleared all WKWebView cookies and cache.")
            }
        }
        // Clears variables
        self.clear()
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

    func appendToHistory(id: UUID, urlString: String, status: Status, album: AlbumEntity, thumbnail: Data?) {
        guard let url = URL(string: urlString) else { return }
        sessionHistory.append(DownloadMediaItem(
            id: id,
            url: urlString,
            downloadedAt: Date.now,
            albumDownloadedTo: album.name,
            domain: url.host(),
            thumbnail: thumbnail
        ))
    }

    func appendToHistory(download: DownloadMediaItem) {
        guard let url = URL(string: download.url) else { return }
        var download = download
        download.domain = url.host()
        sessionHistory.append(download)
    }
    
    func updateHistoryEntity(with newEntity: DownloadMediaItem) {
        self.sessionHistory = self.sessionHistory.map { entity in
            if entity.id != newEntity.id { return entity }
            var mutableEntity = entity
            mutableEntity.thumbnail = newEntity.thumbnail
            return mutableEntity
        }
        //self.sessionHistory.firstIndex(where: { $0.id == id })
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
        //webView?.load(URLRequest(url: URL(string: "about:blank")!))
        self.webView = nil
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
        // If url is nil (cleared state), ignore delegate/KVO updates so currentUrl stays nil
        self.currentUrl = self.url == nil ? nil : url
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
                var apple = document.querySelector('link[rel~="apple-touch-icon"]');
                if (apple) return apple.href;
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
