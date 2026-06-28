//
//  ImageGridView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct MediaImageGridView: View {
    var selectModeActive: Bool
    var thumbnail: UIImage
    var screenType: ScreenType
    
    @Binding var media: SelectMediaEntity           // Used to display the thumbnail
    @Binding var selectedMedia: SelectMediaEntity?  // Used for opening sheet when not in select mode
    @Binding var selectCount: Int
 
    var determineColor: Color {
        if self.selectModeActive {
            switch media.select {
            case .blank:
                return .clear
            case .checked:
                return .green
            }
        } else {
            return .clear
        }
    }
    
    var body: some View {
        ImageGridView(
            thumbnail: thumbnail,
            media: self.media,
            screenType: screenType
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(determineColor, lineWidth: 2)
        )
        .onTapGesture { onTapSelect() }
    }
    
    private func onTapSelect() {
        if self.selectModeActive {
            switch media.select {
            case .blank:
                media.select = .checked
                self.selectCount += 1
            case .checked:
                media.select = .blank
                self.selectCount += 1
            }
        } else {
            self.selectedMedia = media
        }
    }
}
