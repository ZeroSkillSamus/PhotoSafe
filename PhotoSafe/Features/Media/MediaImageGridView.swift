//
//  ImageGridView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct MediaImageGridView: View {
    var is_select_mode_active: Bool
    var ui_image: UIImage

    @Binding var media_select: SelectMediaEntity
    @Binding var selected_media: SelectMediaEntity? // Used for opening sheet when not in select mode
    @Binding var select_count: Int

    var show_background: Bool {
        media_select.media.is_favorited || media_select.media.type == MediaType.Video.rawValue
    }
    
    var body: some View {
        ImageGridView(ui_image: ui_image, media: self.media_select.media)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(determine_color(media: media_select), lineWidth: 2)
            )
            .onTapGesture { select_handler() }
    }
    
    private func select_handler() {
        if self.is_select_mode_active {
            switch media_select.select {
            case .blank:
                media_select.select = .checked
                self.select_count = select_count + 1
            case .checked:
                media_select.select = .blank
                self.select_count = select_count - 1
            }
        } else {
            self.selected_media = media_select
        }
    }
    
    /// Determines the color of the selected item
    /// Green -> Checked
    private func determine_color(media: SelectMediaEntity) -> Color {
        if self.is_select_mode_active {
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
}
