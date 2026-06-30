//
//  TopHeader.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct TopHeader: View {
    @EnvironmentObject var favoritesViewModel: FavoriteViewModel
    @ObservedObject var album_vm: AlbumViewModel
    @Binding var is_edit_enabled: Bool
    
    @State private var display_sheet: Bool = false
    //TODO: - Feature for v2 
    @State private var displayRecentlyDeletedSheet: Bool = false
    
    var body: some View {
        UniversalHeader(header: {
            Text("Album")
                .default_header()
        }) {
            //             Display Alert Confirming With User
            //             If they Want Albums to be removed
            Button {
                self.displayRecentlyDeletedSheet = true
            } label: {
                Image(systemName:"trash")
                    .font(.system(size: 14,design: .rounded))
                    //.font(.title2)
                    .foregroundColor(Color.c1_text)
            }
            .padding(7)
            .applyLiquidGlassIfSupported(shape: .circle, color: Color.c1_accent, isInteractive: true)
            .disabled(self.album_vm.albums.isEmpty)
        } trailing_button: {
            // Created a menu for now
            //  1) Allow User To Edit Albums
            //     -> Choose Where they are placed
            //     -> Choose which ones to delete
            Button {
                withAnimation {
                    self.is_edit_enabled.toggle()
                }
            } label: {
                Text(self.is_edit_enabled ? "Cancel" : "Edit")
                    .foregroundStyle(Color.c1_text)
                    .font(.system(size: 14,design: .rounded))
            }
            .padding(7)
            .applyLiquidGlassIfSupported(color: Color.c1_accent, isInteractive: true)
        }
    }
}
