//
//  WebView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct WebView: View {
    var body: some View {
        VStack  {
            UniversalHeader(header: "Web") {
                EmptyView()
            } trailing_button: {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
    }
}

#Preview {
    WebView()
}
