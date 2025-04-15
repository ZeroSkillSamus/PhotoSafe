//
//  ProgressAlert.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct CustomAlertView<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 15) {
            VStack(spacing: 5) {
                content
            }
        }
        .padding(.vertical, 25)
        .frame(maxWidth: 270)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

