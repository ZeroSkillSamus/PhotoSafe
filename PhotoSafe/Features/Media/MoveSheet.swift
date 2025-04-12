//
//  MoveSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct MoveSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var album_VM: AlbumViewModel
   
    @ObservedObject var media_VM: MediaViewModel
    var curr_album_name: String? = nil

    @State private var toggle_alert: Bool = false
    @State private var album_name: String = ""
    @State private var album_password: String = ""
    
    var move_action: (_ album: AlbumEntity) -> Void
    
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
    
 
    
    var body: some View {
        ZStack {
            /*Color.grayscale(/*@START_MENU_TOKEN@*/0.50/*@END_MENU_TOKEN@*/).ignoresSafeArea()*/ // Background color
            //Color.brown.ignoresSafeArea()
            Color(red: 28/255, green: 28/255, blue: 30/255).ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Move Selected")
                        .font(.title2.bold())
                }
                .frame(maxWidth: .infinity,alignment: .leading)
                .padding()
                
                LazyVStack(spacing: 0) {
                    ForEach(self.album_VM.albums.filter({$0.name != curr_album_name ?? "" }),id:\.self) { album in
                        MoveButtonLabel(name: album.name, image: AlbumImageDisplay(album: album)) {
                            self.move_action(album)
                            self.dismiss()
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
        }
        .alert("Create Album", isPresented: self.$toggle_alert) {
            VStack(spacing: 5) {
                TextField("Name", text: self.$album_name)
                    .foregroundStyle(.black)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                
                TextField("Password", text: self.$album_password)
                    .foregroundStyle(.black)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            Button("OK", action: {
                // Create Album
                self.album_VM.create_album(
                    name: self.album_name,
                    image_data: nil,
                    password: self.album_password
                )
                
                // Fetch Newly Created Album
                if let album = self.album_VM.albums.first(where: {$0.name == album_name}) {
                    self.move_action(album)
                    self.dismiss()
                }
            })
            .disabled(self.album_name.isEmpty)
            
            Button("Cancel",action: {})
        } message: {
            Text("Action Will Create & Move Selected Media To New Album!")
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        // Handles making the sheet height dynamic based on album_count + 2
        .presentationDetents([.height(CGFloat(self.album_VM.albums.count + 2) * 80)])
        .presentationDragIndicator(.visible)
    }
}
