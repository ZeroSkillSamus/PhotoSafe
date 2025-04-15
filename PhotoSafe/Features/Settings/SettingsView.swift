//
//  SettingsView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            UniversalHeader(header: "Settings") {
                EmptyView()
            } trailing_button: {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .background(Color.c1_background)
    }
}

#Preview {
    SettingsView()
}
