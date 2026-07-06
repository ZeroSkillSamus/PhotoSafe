//
//  MoveSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct MoveSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var albumViewModel: AlbumViewModel
   
    var curr_album_name: String? = nil
    var itemCount: Int
    
    @State private var toggle_alert: Bool = false
    @State private var album_name: String = ""
    @State private var album_password: String = ""
    
    var move_action: (_ album: AlbumEntity) -> Void
    
    struct MoveButtonLabel<Content: View>: View {
        let name: String
        let subtitle: String?
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
                    
                    VStack(alignment: .leading) {
                        Text(name)
                            .font(.system(size: 15,weight: .semibold,design: .rounded))
                            .foregroundStyle(.white)
                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 13,weight: .semibold,design: .rounded))
                                .foregroundStyle(.white)
                                .opacity(0.7)
                        }
                    }
                    
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
    
    var header: String {
        if itemCount < 1 { return "Move Items"}
        if itemCount == 1 { return "Move 1 Item" }
        return "Move \(itemCount) Items"
    }
    
    var isAlbumsEmpty: Bool {
        self.albumViewModel.albums.filter({$0.name != curr_album_name}).isEmpty
    }
    
    var heightCalculate: CGFloat {
        let offSet = isAlbumsEmpty ? 1 : 2
        return CGFloat(self.albumViewModel.albums.count + offSet) * 90
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.c1_text)
                            .font(.system(size: 20,weight: .semibold,design: .rounded))
                    }
                    .padding(10)
                    .applyLiquidGlassIfSupported(shape: .circle,color: Color.c1_accent.opacity(0.7))
                    
                    Spacer()
                }
                .padding(8)
                .padding(.top,5)
                .padding(.horizontal,8)
                .overlay(alignment: .center) {
                    VStack(alignment: .center) {
                        // Header
                        Text(header)
                            .font(.system(size: 22,weight: .semibold,design: .rounded))
                        Text("Choose an album destination")
                            .font(.system(size: 16,weight: .semibold,design: .rounded))
                            .opacity(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.c1_text)
                }
                
                
                // New Album Options
                MoveButtonLabel(
                    name: "New Album",
                    subtitle: "Create and move selected items",
                    image: Image("NoImageFound").resizable()
                ) {
                    // Toggle alert that will prompt user to enter new album name
                    self.toggle_alert = true
                }
                .padding(.horizontal,8)
                .padding(.bottom,10)
                
                if !isAlbumsEmpty {
                    Section {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(self.albumViewModel.albums.filter({$0.name != curr_album_name ?? "" }),id:\.self) { album in
                                    MoveButtonLabel(
                                        name: album.name,
                                        subtitle: "\(album.mediaCount) items",
                                        image: AlbumImageDisplay(album: album))
                                    {
                                        self.move_action(album)
                                        self.dismiss()
                                    }
                                    Divider()
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                        
                    } header: {
                        Text("Albums")
                            .foregroundStyle(Color.c1_text)
                            .font(.system(size: 16,weight: .semibold,design: .rounded))
                            .frame(maxWidth: .infinity,alignment: .leading)
                            .padding(.horizontal,8)
                    }
                    .padding(.horizontal,8)
                }
            }
            
//            VStack {
//                HStack {
//                    Text("Move Selected")
//                        .font(.title2.bold())
//                        .foregroundStyle(Color.c1_text)
//                }
//                .frame(maxWidth: .infinity,alignment: .leading)
//                .padding()
//                
//                ScrollView {
//                    LazyVStack(spacing: 0) {
//                        ForEach(self.album_VM.albums.filter({$0.name != curr_album_name ?? "" }),id:\.self) { album in
//                            MoveButtonLabel(name: album.name, image: AlbumImageDisplay(album: album)) {
//                                self.move_action(album)
//                                self.dismiss()
//                            }
//                            Divider()
//                                .foregroundStyle(.black)
//                        }
//                        
//                        // Create New Album Button
//                        MoveButtonLabel(
//                            name: "Create & Move To New Album",
//                            image: Image("NoImageFound").resizable()
//                        ) {
//                            // Toggle alert that will prompt user to enter new album name
//                            self.toggle_alert = true
//                        }
//                    }
//                }
//            }
        }
        .fullScreenCover(isPresented: self.$toggle_alert, content: {
            CreateAlbumSheet(isPlusModeActive: .constant(true), header: "Create Album & Move To", moveAction: { createdAlbumName in
                self.album_name = createdAlbumName
                guard let createdAlbum = self.albumViewModel.albums.first(where: {$0.name == self.album_name}) else {
                    return
                }
                self.move_action(createdAlbum)
                self.dismiss()
            })
        })
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        // Handles making the sheet height dynamic based on album_count + 2
        //.presentationBackground(.ultraThinMaterial)
        .presentationDetents([.height(self.heightCalculate)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.c1_secondary.opacity(0.7))
        .interactiveDismissDisabled()
        .onDisappear {
            print("running?")
        }
    }
}
