//
//  PhotoSafeApp.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/25/25.
//

import UIKit
import SwiftUI

class PassthroughWindow: UIWindow {
    var authViewModel: AuthStorageViewModel?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let auth = authViewModel,
              auth.showPrivacyOverlay || (!auth.isUnlocked) else {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var secureWindow: UIWindow?
    
    // Hold a reference to the view model so both windows can read it
    private let authViewModel = AuthStorageViewModel()
    private let webViewModel = WebViewModel()
    private let slideShowViewModel = SlideShowViewModel()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // 1. App Window
        let mainWindow = UIWindow(windowScene: windowScene)
        mainWindow.rootViewController = UIHostingController(
            rootView: BottomTabNavigation().environmentObject(authViewModel).environmentObject(slideShowViewModel).environment(webViewModel)
        )
        self.window = mainWindow
        mainWindow.makeKeyAndVisible()
        
        // 2. Security/Privacy Window
        let topWindow = PassthroughWindow(windowScene: windowScene)
        topWindow.windowLevel = .alert + 1
        topWindow.backgroundColor = .clear
        topWindow.authViewModel = authViewModel

        let secureVC = UIHostingController(
            rootView: SecureOverlayContainer().environmentObject(authViewModel)
        )
        secureVC.view.backgroundColor = .clear
        topWindow.rootViewController = secureVC

        self.secureWindow = topWindow
        topWindow.makeKeyAndVisible()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        authViewModel.showPrivacyOverlay = false
    }

    func sceneWillResignActive(_ scene: UIScene) {
        if authViewModel.isUnlocked {
            authViewModel.showPrivacyOverlay = true
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        authViewModel.lockApp()
        webViewModel.clear()  // clear alongside lock
        print("sdakjsdakj")
    }
}

struct SecureOverlayContainer: View {
    @EnvironmentObject var authViewModel: AuthStorageViewModel

    var body: some View {
        ZStack {
            // Lower priority (bottom)
            if !authViewModel.isUnlocked {
                LockView()
                    .transition(.move(edge: .bottom))
            }
            
            // Higher priority (top)
            if authViewModel.showPrivacyOverlay {
                AppPrivacyOverlay()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authViewModel.showPrivacyOverlay)
        .animation(.easeInOut(duration: 0.25), value: authViewModel.isUnlocked)
    }
}

@main
struct PhotoSafeApp: App {
    // Tells SwiftUI to use UIKit's lifecycle via SceneDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Leave this empty or standard. SceneDelegate handles window creation.
        WindowGroup {
            EmptyView()
        }
    }
}

struct AppPrivacyOverlay: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .frame(width: 45,height: 60)
                .foregroundStyle(Color.c1_primary)
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .background(Color.c1_background)
    }
}
