//
//  Untitled.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/16/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    func applyLiquidGlassIfSupported(
        shape: any Shape = .capsule,
        color: Color = .primary,
        isInteractive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            self
                .contentShape(shape)
                .glassEffect(.regular.tint(color).interactive(isInteractive), in: shape)
        } else {
            self
                .contentShape(Capsule())
        }
    }
}
