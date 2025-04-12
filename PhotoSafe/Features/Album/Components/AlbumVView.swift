//
//  AlbumVView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/6/25.
//

import SwiftUI

struct AlbumVDisplay: View {
    @EnvironmentObject private var album_VM: AlbumViewModel
    
    var album: AlbumEntity
    //@State private var offset: CGFloat = 0
    @State private var isSwiped = false
    @Binding var is_edit_enabled: Bool
    
    private let edit_mode_width: CGFloat = -80
    
    var body: some View {
        ZStack {
            Button {
                self.album_VM.delete(album: album)
                
                // After delete and list is empty, exit out of edit mode
                if album_VM.albums.isEmpty {
                    withAnimation {
                        self.is_edit_enabled.toggle()
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    VStack(spacing: 5) {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                        
                        Text("Delete")
                            .font(.system(size: 15,weight: .medium,design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .frame(width: 80,height: 120)
                    .background(.red)
                }
            }
            .opacity(self.is_edit_enabled ? 1 : 0)
            
            VStack(spacing:0) {
                HStack {
                    VStack {
                        AlbumImageDisplay(album: album)
                            .frame(width: 130, height:120)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    
                    HStack {
                        Text(album.name)
                            .foregroundStyle(Color.c1_text)
                            .padding(.leading,20)
                            .font(.system(size: 18,weight: .medium,design: .rounded))
                        
                        Spacer()
                        
                        if album.is_locked {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                                .foregroundColor(Color.c1_primary)
                                .padding(.trailing,20)
                        }
                    }
                    .frame(maxWidth:.infinity)
                }
                
                Divider()
            }
            .background(Color.c1_background)
            .offset(x: self.is_edit_enabled ? self.edit_mode_width : 0)
        }
    }
}
