//
//  ImageCircleOverlay.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

/// A circular view containing a centered SF Symbol image, commonly used for buttons or icons.
///
/// This view creates a perfect circle with a customizable background color and system image.
///
/// ## Example Usage:
/// ```swift
/// ImageCircleOverlay(
///     color: .red,
///     icon: ImageCircleOverlay.IconType.symbol("minus"),
///     frame: CGSize(width: 60, height: 60)
/// )
///
/// ```
///
/// - Parameters:
///   - color: The background color of the circle. Defaults to `.blue`.
///   - icon: IconType Enum which differentiates between symbol & text. Defaults to `.symbol("plus")`.
///   - frame: The width and height of the circular frame. Defaults to `70x70`.
///
/// - Tag: ImageCircleOverlay
/// - Author: Abraham Mitchell
/// - Version: 1.0
/// - Copyright: Your Company
/// - Important: Ensure the icon exists in SF Symbols or provide a fallback.
struct ImageCircleOverlay: View {
    enum IconType {
        case symbol(String)
        case text(String)
    }

    var color: Color = .blue
    var icon: IconType = .symbol("plus")
    var frame: CGSize = CGSize(width: 70, height: 70)
    
    var body: some View {
        ZStack {
            Circle().fill(color)
            Group {
                switch icon {
                case .symbol(let symbol):
                    Image(systemName: symbol)
                case .text(let text):
                    Text(text)
                }
            }
            .font(.title3)
            .foregroundStyle(.white)
        }
        .frame(width: frame.width,height: frame.height)
    }
}
