//
//  OrientationLockModifier.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/5/26.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .all

    func application(
      _ application: UIApplication,
      supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

struct OrientationLockModifier: ViewModifier {
    let orientation: UIInterfaceOrientationMask
    
    func body(content: Content) -> some View {
        content
            .task {
                await updateOrientation()
            }
            .onChange(of: orientation) { _,_ in
                Task { await updateOrientation() }
            }
    }
    
    private func updateOrientation() async {
        // Update app-wide orientation lock
        AppDelegate.orientationLock = orientation
        
        // Modern approach for iOS 16+
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            windowScene.windows.first?.rootViewController?
                .setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

extension View {
    func orientationLock(_ orientation: UIInterfaceOrientationMask) -> some View {
        self.modifier(OrientationLockModifier(orientation: orientation))
    }
}
