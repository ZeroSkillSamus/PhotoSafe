//
//  PhotoSafeApp.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/25/25.
//

import SwiftUI

@main
struct PhotoSafeApp: App {
    var body: some Scene {
        WindowGroup {
            BottomTabNavigation().preferredColorScheme(.dark)
        }
    }
}
