//
//  PhotoSafeApp.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/25/25.
//

import SwiftUI

@main
struct PhotoSafeApp: App {
    @StateObject private var album_VM: AlbumViewModel = AlbumViewModel()
    
    var body: some Scene {
        WindowGroup {
            //LockScreen().preferredColorScheme(.dark)
            AlbumView().preferredColorScheme(.dark)
                .environmentObject(self.album_VM)
            //ContentView().preferredColorScheme(.dark)
        }
    }
}
