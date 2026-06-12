//
//  WebView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI
import WebKit

struct WebViewWrapper: View {
    @Environment(WebViewModel.self) var webViewModel
    
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
        .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .center)
        .background(Color.c1_background)
    }
    
    @ViewBuilder
    func defaultView() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .frame(width: 100,height: 120)
                .foregroundStyle(Color.c1_primary)
            
            VStack(spacing: 15) {
                Text("Browse privately, stay protected!")
                    .font(.system(size: 18,weight: .semibold,design: .rounded))
                    .foregroundStyle(Color.c1_accent)
                
                Text("Your activity stays yours. This browser leaves no history, stores no cookies, and clears everything when you leave. Links always open over HTTPS, and searches go through DuckDuckGo — a search engine that never tracks you.")
                    .foregroundStyle(Color.c1_primary)
                    .font(.system(size: 15,weight: .regular,design: .rounded))
                
                Text("What you browse here, stays here.")
                    .foregroundStyle(Color.c1_primary)
                    .font(.system(size: 15,weight: .regular,design: .rounded))
                    .italic()
            }
            
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
        .padding()
        .background(Color.c1_background)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            WebVavigationBar(webViewModel: self.webViewModel)
            
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
    }
}

struct WebView: UIViewRepresentable {
    var webViewModel: WebViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all

        let longPressScript = WKUserScript(
            source: """
            (function() {
                var longPressTimer = null;
                var DURATION = 500;

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
        
        // Add oberver to track progress of loading page
        view.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        // Add this after creating the view:
        view.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        self.webViewModel.load(view)
        
        //isLoading = true
        webViewModel.webView = view
        view.navigationDelegate = context.coordinator
        
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "imageLongPress")
        uiView.removeObserver(coordinator, forKeyPath: "estimatedProgress")
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // CRITICAL: Only load if we have a URL and the web view is empty AND we're not navigating
        // This prevents interrupting redirects
        if let url = webViewModel.url,
           uiView.url == nil,
           !webViewModel.isNavigating {
            print("Loading initial URL: \(url)")
            self.webViewModel.load(uiView)
        }
        
        // Sync current URL without triggering loads
        if uiView.url != webViewModel.currentUrl {
            webViewModel.update(currentUrl: uiView.url)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(parent: WebView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "imageLongPress",
                  let body = message.body as? [String: Any],
                  let src = body["src"] as? String else { return }
            print("Long pressed image: \(src)")
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
              if keyPath == "estimatedProgress", let webView = object as? WKWebView {
                  parent.webViewModel.progress = webView.estimatedProgress
              }
        }
        
        static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
            uiView.removeObserver(coordinator, forKeyPath: "estimatedProgress")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            let urlString = url.absoluteString
            print("🔍 Navigation action: \(urlString)")
            
            // BLOCK x.com's escape attempts
            if urlString.contains("x-safari-https://") {
                print("🚫 Blocking x.com escape attempt to: \(urlString)")
                decisionHandler(.cancel)
                return
            }
            
            // Block any non-http/https schemes after page loads
            if let scheme = url.scheme?.lowercased(),
               scheme != "http" && scheme != "https" {
                print("🚫 Blocking non-web scheme: \(scheme)")
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ didFinish: \(webView.url?.absoluteString ?? "unknown")")
            parent.webViewModel.update(isLoading: false, isNavigating: false)
            parent.webViewModel.update(currentUrl: webView.url)
            
            if let url = webView.url {
                parent.webViewModel.update(url: url)
            }
            
            // Inject JavaScript to prevent x.com from redirecting
            let preventEscapeScript = """
            // Prevent custom scheme redirects
            (function() {
                // Save the original methods
                const originalAssign = window.location.assign;
                const originalReplace = window.location.replace;
                const originalOpen = window.open;
                
                // Override to block x-safari-https
                window.location.assign = function(url) {
                    if (url && url.toString().includes('x-safari-https')) {
                        console.log('Blocked escape attempt via assign');
                        return;
                    }
                    return originalAssign.call(this, url);
                };
                
                window.location.replace = function(url) {
                    if (url && url.toString().includes('x-safari-https')) {
                        console.log('Blocked escape attempt via replace');
                        return;
                    }
                    return originalReplace.call(this, url);
                };
                
                window.open = function(url) {
                    if (url && url.toString().includes('x-safari-https')) {
                        console.log('Blocked escape attempt via open');
                        return null;
                    }
                    return originalOpen.call(this, url);
                };
                
                // Also block clicks on elements that might trigger escape
                document.addEventListener('click', function(e) {
                    let target = e.target.closest('a');
                    if (target && target.href && target.href.includes('x-safari-https')) {
                        e.preventDefault();
                        e.stopPropagation();
                        console.log('Blocked escape attempt via link click');
                        return false;
                    }
                }, true);
                
                console.log('X.com escape protection active');
            })();
            """
            
            webView.evaluateJavaScript(preventEscapeScript) { _, error in
                if let error = error {
                    print("JavaScript injection failed: \(error)")
                } else {
                    print("✅ Escape prevention script injected")
                }
            }
        }
        
        // Also add this to handle the redirect response
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            print("📥 Response for: \(navigationResponse.response.url?.absoluteString ?? "unknown")")
            
            // Allow the response
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("didStartProvisionalNavigation")
            parent.webViewModel.update(isLoading: true)
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            print("didCommit")
        }
        
        // Error Handling
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
            print("Failed navigation: \(error.localizedDescription)")
            if (error as NSError).code == NSURLErrorCancelled {
                print("Navigation was cancelled (likely goBack/goForward)")
                parent.webViewModel.update(isLoading: false)
                parent.webViewModel.update(currentUrl: webView.url)
            } else if (error as NSError).domain == "WebKitErrorDomain" && (error as NSError).code == 102 {
                print("Frame load interrupted (likely due to redirect or sanitization). Ignoring.")
                // Reset your loading flags here to keep the UI responsive
                parent.webViewModel.update(isLoading: false)
                return
            }
            else {
                parent.webViewModel.update(isLoading: false, error: error)
            }
        }
        
        // 3. Called if an error occurs during provisional navigation (e.g. offline/timeout).
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("Failed provisional navigation: \(error.localizedDescription)")
            if (error as NSError).code == NSURLErrorCancelled {
                print("Navigation was cancelled (likely goBack/goForward)")
                parent.webViewModel.update(isLoading: false)
            } else if (error as NSError).domain == "WebKitErrorDomain" && (error as NSError).code == 102 {
                print("Frame load interrupted (likely due to redirect or sanitization). Ignoring.")
                // Reset your loading flags here to keep the UI responsive
                parent.webViewModel.update(isLoading: false)
                return
            }
            else {
                parent.webViewModel.update(isLoading: false, error: error)
            }
            
            // If error display url errored on
            print("Errored url ", webView.url?.absoluteString ?? "")
            print("Errored url ", parent.webViewModel.currentUrl ?? "")
            parent.webViewModel.update(currentUrl: parent.webViewModel.currentUrl)
            
        }
        
    }
}
