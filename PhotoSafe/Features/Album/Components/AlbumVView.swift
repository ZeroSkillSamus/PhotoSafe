//
//  AlbumVView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/6/25.
//

import SwiftUI

struct AlbumVDisplay: View {
    var album: AlbumEntity
    //@State private var offset: CGFloat = 0
    @State private var isSwiped = false
    @Binding var is_edit_enabled: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 5) {
                Image(systemName: "trash.fill")
                    .font(.title3)
  
                Text("Delete")
                    .font(.system(size: 15,weight: .medium,design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal)
            .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .trailing)
            .background(.red)

            HStack {
                VStack {
                    AlbumImageDisplay(album: album)
                        .frame(width: 130, height:120)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                
                HStack {
                    Text(album.name)
                        .foregroundStyle(.white)
                        .padding(.leading,20)
                        .font(.system(size: 18,weight: .medium,design: .rounded))
                    
                    Spacer()
                    
                    if album.is_locked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(.trailing,20)
                    }
                }
                .frame(maxWidth:.infinity)
            }
            .background(.black)
            .offset(x: self.is_edit_enabled ? -80 : 0)
        }
    }
}
