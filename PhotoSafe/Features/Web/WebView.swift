//
//  WebView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI
import WebKit

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

        // Disable geolocation
        let blockGeolocationScript = WKUserScript(
            source: """
                    (function() {
                    Object.defineProperty(navigator, 'geolocation', { get: function() { return undefined; } });
                    })();
                    """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(blockGeolocationScript)

        // Intercept fetch/XHR to capture video URLs before MSE consumes them (Twitter/X)
        let captureVideoURLsScript = WKUserScript(
            source: """
            (function() {
                var _captured = [];
                window.__capturedVideoURLs = _captured;

                function isVideoURL(url) {
                    return url && (
                        url.includes('.m3u8') ||
                        url.includes('video.twimg.com') ||
                        url.includes('/video/') ||
                        url.includes('.mp4') ||
                        url.includes('.ts')
                    );
                }

                var _fetch = window.fetch;
                window.fetch = function() {
                    var input = arguments[0];
                    var url = typeof input === 'string' ? input : (input && input.url ? input.url : null);
                    if (url && isVideoURL(url) && url.startsWith('http')) {
                        _captured.unshift(url);
                        if (_captured.length > 20) _captured.length = 20;
                    }
                    return _fetch.apply(this, arguments);
                };

                var _open = XMLHttpRequest.prototype.open;
                XMLHttpRequest.prototype.open = function(method, url) {
                    if (typeof url === 'string' && isVideoURL(url) && url.startsWith('http')) {
                        _captured.unshift(url);
                        if (_captured.length > 20) _captured.length = 20;
                    }
                    return _open.apply(this, arguments);
                };
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(captureVideoURLsScript)

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
                            window.webkit.messageHandlers.imageLongPress.postMessage({ src: src, type: 'image' });
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

                // Resolve a real http/https URL from a video element (handles MSE blob URLs)
                function resolveVideoSrc(video, path) {
                    var src = video.currentSrc || video.src;
                    if (src && !src.startsWith('blob:')) return src;

                    // Check <source> children
                    var sources = video.querySelectorAll('source');
                    for (var i = 0; i < sources.length; i++) {
                        var s = sources[i].src;
                        if (s && !s.startsWith('blob:')) return s;
                    }

                    // Scan composedPath — already pierces shadow DOM, includes shreddit-player wrapper
                    var videoAttrs = ['src', 'hls-url', 'data-hls-url', 'data-src', 'data-video-src', 'packaged-media-json'];
                    for (var i = 0; i < path.length; i++) {
                        var el = path[i];
                        if (!el || !el.getAttribute) continue;
                        for (var j = 0; j < videoAttrs.length; j++) {
                            var val = el.getAttribute(videoAttrs[j]);
                            if (!val) continue;
                            // packaged-media-json is a JSON blob — extract first m3u8 URL from it
                            if (val.charAt(0) === '{') {
                                try {
                                    var m = JSON.stringify(JSON.parse(val)).match(/"(https?:[^"]+\\.m3u8[^"]*)"/);
                                    if (m) return m[1];
                                } catch(e) {}
                            }
                            if (!val.startsWith('blob:') && (val.startsWith('http') || val.includes('.m3u8'))) return val;
                        }
                    }

                    // Twitter/MSE fallback: use most recently captured m3u8 URL
                    if (window.__capturedVideoURLs && window.__capturedVideoURLs.length > 0) {
                        return window.__capturedVideoURLs[0];
                    }

                    return null;
                }

                // Video detection — composedPath + elementFromPoint + playing video fallback
                var videoTimer = null;
                document.addEventListener('touchstart', function(e) {
                    var path = e.composedPath ? e.composedPath() : [];
                    var video = null;

                    // Pass 1: composedPath (handles shadow DOM)
                    for (var i = 0; i < path.length; i++) {
                        if (path[i].nodeName === 'VIDEO') { video = path[i]; break; }
                    }

                    // Pass 2: elementFromPoint + parent/sibling walk (handles overlay divs)
                    if (!video && e.touches && e.touches[0]) {
                        var el = document.elementFromPoint(e.touches[0].clientX, e.touches[0].clientY);
                        var curr = el;
                        var depth = 0;
                        while (curr && depth < 8) {
                            if (curr.nodeName === 'VIDEO') { video = curr; break; }
                            // check children for video sibling
                            var childVideo = curr.querySelector('video');
                            if (childVideo) { video = childVideo; break; }
                            curr = curr.parentElement;
                            depth++;
                        }
                    }

                    // Pass 3: any currently playing video on the page
                    if (!video) {
                        var all = document.querySelectorAll('video');
                        for (var j = 0; j < all.length; j++) {
                            if (all[j].currentTime > 0 || !all[j].paused) { video = all[j]; break; }
                        }
                    }

                    // Debug: always log what was captured so we can trace
                    window.webkit.messageHandlers.debugVideoURLs.postMessage({
                        found: !!video,
                        captured: window.__capturedVideoURLs || []
                    });

                    if (!video) return;
                    var src = resolveVideoSrc(video, path);
                    if (!src) return;
                    videoTimer = setTimeout(function() {
                        window.webkit.messageHandlers.imageLongPress.postMessage({ src: src, type: 'video' });
                    }, DURATION);
                }, { passive: true, capture: true });
                document.addEventListener('touchend', function() { clearTimeout(videoTimer); }, { capture: true });
                document.addEventListener('touchmove', function() { clearTimeout(videoTimer); }, { passive: true, capture: true });
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(longPressScript)
        config.userContentController.add(context.coordinator, name: "imageLongPress")
        config.userContentController.add(context.coordinator, name: "debugVideoURLs")

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
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "debugVideoURLs")
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
            if message.name == "debugVideoURLs" {
                print("🎬 Captured video URLs:", message.body)
                return
            }
            guard message.name == "imageLongPress",
                  let body = message.body as? [String: Any],
                  let src = body["src"] as? String,
                  let url = URL(string: src),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "https" || scheme == "http" else { return }
            let mediaType = (body["type"] as? String) == "video" ? WebMediaType.video : WebMediaType.image
            print("Longpressed", mediaType)
            parent.webViewModel.pendingImageURL = ImageURLItem(url: src, mediaType: mediaType)
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            guard let webView = object as? WKWebView else { return }
            if keyPath == "estimatedProgress" {
                parent.webViewModel.progress = webView.estimatedProgress
            } else if keyPath == "URL" {
                parent.webViewModel.update(currentUrl: webView.url)
            }
        }

        // If a website wants mic/camera access auto block it 
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.deny)
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
