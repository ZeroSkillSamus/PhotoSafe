//
//  MoveSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct MoveSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var album_VM: AlbumViewModel
    
    @ObservedObject var media_VM: MediaViewModel
    var curr_album: AlbumEntity
    @Binding var num_selected_items: Int
    @Binding var select_mode_active: Bool
    
    @State private var toggle_alert: Bool = false
    @State private var album_name: String = ""
    @State private var album_password: String = ""
    
    struct MoveButtonLabel<Content: View>: View {
        let name: String
        let image: Content
        let action: () -> Void
        
        
        var body: some View {
            Button {
                self.action()
            } label: {
                HStack(spacing: 20) {
                    image
                        .frame(width: 60,height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    
                    Text(name)
                        .font(.system(size: 15,weight: .semibold,design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    
                    Image(systemName: "greaterthan")
                        .font(.system(size: 15,weight: .semibold,design: .rounded))
                        .foregroundStyle(.white)
                    
                }
                .frame(maxWidth: .infinity,alignment: .leading)
                .padding()
            }
        }
    }
    
    /// Handles moving the selected media to the album passed in
    /// If the album becomes empty toggle the select mode
    /// Close the sheet once the move has finished executing
    func move_handler(for album: AlbumEntity) {
        self.num_selected_items = 0
        withAnimation {
            self.media_VM.move_selected(to: album)
            
            // Only close select mode if medias is empty after moving
            if self.media_VM.medias.isEmpty { self.select_mode_active.toggle() }
            
            self.dismiss()
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Move Selected")
                    .font(.title2.bold())
            }
            .frame(maxWidth: .infinity,alignment: .leading)
            .padding()
            
            LazyVStack(spacing: 0) {
                ForEach(self.album_VM.albums.filter({$0.name != curr_album.name }),id:\.self) { album in
                    MoveButtonLabel(name: album.name, image: AlbumImageDisplay(album: album)) {
                        self.move_handler(for: album)
                    }
                    Divider()
                        .foregroundStyle(.white)
                }
                
                // Create New Album Button
                MoveButtonLabel(
                    name: "Create & Move To New Album",
                    image: Image("NoImageFound").resizable())
                {
                    // Toggle alert that will prompt user to enter new album name
                    self.toggle_alert = true
                }
            }
        }
        .alert("Create Album", isPresented: self.$toggle_alert) {
            VStack(spacing: 5) {
                TextField("Name", text: self.$album_name)
                TextField("Password", text: self.$album_password)
            }
            
            Button("OK", action: {
                // Create Album
                self.album_VM.create_album(
                    name: self.album_name,
                    image_data: nil,
                    password: self.album_password.isEmpty ? nil : self.album_password
                )
                
                // Fetch Newly Created Album
                if let album = self.album_VM.albums.first(where: {$0.name == album_name}) {
                    self.move_handler(for: album)
                }
            })
            .disabled(self.album_name.isEmpty)
            
            Button("Cancel",action: {})
        } message: {
            Text("Action Will Create & Move Selected Media To New Album!")
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        // Handles making the sheet height dynamic based on album_count + 2
        .presentationDetents([.height(CGFloat(self.album_VM.albums.count + 2) * 70)])
        .presentationDragIndicator(.visible)
    }
}
