//
//  TopHeader.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct TopHeader: View {
    @ObservedObject var album_vm: AlbumViewModel
    
    @State private var display_sheet: Bool = false
    @State private var display_delete_alert: Bool = false
    
    var body: some View {
        //VStack(spacing:0) {
            HStack {
                // Display Alert Confirming With User
                // If they Want Albums to be removed
                Button {
                    self.display_delete_alert = true
                } label: {
                    Image(systemName:"trash.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // Created a menu for now
                // 1) Allow User To Edit Albums
                //    -> Choose Where they are placed
                //    -> Choose which ones to delete
                Button {
                    print("Edit")
                } label: {
                    Text("Edit")
                }
            }
            .frame(height:24)
            .padding(.horizontal)
            .padding(.vertical,10)
            .overlay(
                Text("Albums")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            )
//            .sheet(isPresented: self.$display_sheet) {
//                CreateAlbumSheet(album_vm: self.album_vm)
//            }
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
            .background(.bar)
        //}
        
        
    }
}
