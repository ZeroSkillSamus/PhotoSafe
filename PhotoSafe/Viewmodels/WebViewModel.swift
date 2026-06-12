//
//  WebViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import Foundation
import WebKit

@Observable
class WebViewModel {
    private let defaultSearchEngine: String = "https://duckduckgo.com/?q="
    
    var url: URL? = nil
    var currentUrl: URL? = nil
    var progress: Double = 0
    
    var isLoading: Bool = false
    var error: Error? = nil
    
    weak var webView: WKWebView?
    
    var canGoBack: Bool = false
    var canGoFoward: Bool = false
    
    var isNavigating: Bool = false
    
    // var canGoBack: Bool
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
    
    func goBack() {
        if !canGoBack { return }
        print("back")
        webView?.goBack()
    }
    
    func goForward() {
        if !canGoFoward { return }
        print("forward")
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
    }

    func userNavigateTo(urlString: String) {
        updateNavigationState()
        self.error = nil
        
        print(urlString)
        var newUrl = urlString.lowercased().trimmingCharacters(in:.whitespaces)
        
        // Check if user typed a url
        if !isUrl(urlString: newUrl) {
            guard let encodedQuery = newUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            newUrl = defaultSearchEngine + encodedQuery
            // Set query using default search engine duckduckgo
        } else if !newUrl.hasPrefix("https://") {
            newUrl = "https://" + newUrl
        } else if newUrl.hasPrefix("http://") {
            // Upgrade any http connection to https
            newUrl = newUrl.replacingOccurrences(of: "http://", with: "https://")
        }
        
        self.update(url: URL(string: newUrl))
        
        guard let url = URL(string: newUrl) else { return }
        print("User navigating to", url.absoluteString)
        webView?.load(URLRequest(url: url))
    }
    
    func update(currentUrl url: URL?) {
        self.currentUrl = url
        self.updateNavigationState()
    }
    
    func load(_ webView: WKWebView) {
        // Check for prefix here
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
}
