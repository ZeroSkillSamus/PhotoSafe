//
//  MediaDisplay.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/28/25.
//

import SwiftUI

struct MediaDisplay: View {
    var name: String
    
    var body: some View {
        VStack {
            Text("Content Displayed Here")
        }
        .navigationTitle(name)
    }
}

#Preview {
    MediaDisplay(name: "Fun")
}
