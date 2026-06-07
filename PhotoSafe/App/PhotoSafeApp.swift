//
//  PhotoSafeApp.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/25/25.
//

import SwiftUI

@main
struct PhotoSafeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authViewModel = AuthStorageViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showPrivacyOverlay = true
    var body: some Scene {
        WindowGroup {
            ZStack {
                let unlocked = authViewModel.isPinSet && authViewModel.isUnlocked
                BottomTabNavigation()
                    .allowsHitTesting(unlocked)
                    .opacity(unlocked ? 1 : 0)
                    .animation(.easeInOut, value: unlocked)
                
                if !unlocked {
                    LockView()
                }
                
                if showPrivacyOverlay {
                    AppPrivacyOverlay()
                }
            }
            
        }
        .environmentObject(authViewModel)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                showPrivacyOverlay = false
            case .background:
                authViewModel.lockApp()
            case .inactive:
                showPrivacyOverlay = !authViewModel.isUnlocked ? false : true
            default:
                break
            }
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
