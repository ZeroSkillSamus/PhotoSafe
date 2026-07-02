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
            VStack {
                HStack {
                    Text("Move Selected")
                        .font(.title2.bold())
                        .foregroundStyle(Color.c1_text)
                }
                .frame(maxWidth: .infinity,alignment: .leading)
                .padding()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(self.album_VM.albums.filter({$0.name != curr_album_name ?? "" }),id:\.self) { album in
                            MoveButtonLabel(name: album.name, image: AlbumImageDisplay(album: album)) {
                                self.move_action(album)
                                self.dismiss()
                            }
                            Divider()
                                .foregroundStyle(.black)
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
        }
        .fullScreenCover(isPresented: self.$toggle_alert, content: {
            CreateAlbumSheet(isPlusModeActive: .constant(true), header: "Create Album & Move To", moveAction: { createdAlbumName in
                self.album_name = createdAlbumName
                guard let createdAlbum = self.album_VM.albums.first(where: {$0.name == self.album_name}) else {
                    return
                }
                self.move_action(createdAlbum)
                self.dismiss()
            })
        })
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        // Handles making the sheet height dynamic based on album_count + 2
        //.presentationBackground(.ultraThinMaterial)
        .presentationDetents([.height(CGFloat(self.album_VM.albums.count + 3) * 85)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.c1_secondary.opacity(0.7))
    }
}
