//
//  ImageGridView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI

struct ImageGridView: View {
    var is_selected: Bool
    
    @Binding var media_select: SelectMediaEntity
    @Binding var selected_item: SelectMediaEntity?
    @Binding var select_count: Int
    
    var body: some View {
        if let ui_image = media_select.media.image {
            Image(uiImage: ui_image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .scaleEffect(1.3)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(alignment: .topLeading) {
                    VStack {
                        if media_select.media.type == MediaType.Video.rawValue {
                            Image(systemName: "video.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(5)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(determine_color(media: media_select), lineWidth: 2)
                )
                .onTapGesture { select_handler() }
        }
    }
    
    /// If we are in select mode function will handle if a user taps on a photo it will highlight green for selected items
    /// User can tap the media again to uncheck the item
    /// If we are not in select mode we then set the selected_item, which will open our sheet
    func select_handler() {
        if is_selected {
            switch media_select.select {
            case .blank:
                //self.media_VM.medias[index].select = .checked
                self.media_select.select = .checked
                self.select_count = select_count + 1
            case .checked:
                //self.media_VM.medias[index].select = .blank
                self.media_select.select = .blank
                self.select_count = select_count - 1
            }
        } else {
            self.selected_item = media_select
        }
    }
    
    /// Determines the color of the selected item
    /// Green -> Checked
    func determine_color(media: SelectMediaEntity) -> Color {
        if self.is_selected {
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
