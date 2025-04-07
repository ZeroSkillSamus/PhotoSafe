//
//  AlbumVView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/6/25.
//

import SwiftUI

struct AlbumVDisplay: View {
    var album: AlbumEntity
    
    var body: some View {
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
    }
}
