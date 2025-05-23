//
//  TopHeader.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct TopHeader: View {
    @ObservedObject var album_vm: AlbumViewModel
    @Binding var is_edit_enabled: Bool
    
    @State private var display_sheet: Bool = false
    @State private var display_delete_alert: Bool = false
    
    var body: some View {
        UniversalHeader(header: {
            Text("Album")
                .default_header()
        }) {
            //             Display Alert Confirming With User
            //             If they Want Albums to be removed
            Button {
                self.display_delete_alert = true
            } label: {
                Image(systemName:"trash.fill")
                    .font(.title2)
                    .foregroundColor(self.album_vm.albums.isEmpty ? .gray : .red)
            }
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
            }
        }
        .alert("Delete All Albums?", isPresented: $display_delete_alert) {
            Button("Delete", role: .destructive) {
                withAnimation(.easeInOut) {
                    self.album_vm.deleteAll()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Will Delete All Albums & Media, Are you Sure????")
        }
    }
}
