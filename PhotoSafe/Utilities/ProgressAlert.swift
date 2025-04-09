//
//  ProgressAlert.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI

struct ProgressAlert: View {
    var selected_media_count: Int
    var alert_value: Float
    
    var body: some View {
        VStack(spacing: 15) {
            VStack(spacing: 5) {
                Text("Progress")
                    .font(.title3.bold())
                
                Text("\(Int(self.alert_value))/\(self.selected_media_count)")
                    .font(.footnote.bold())
            }
            
            ProgressView(value: self.alert_value,total: Float(self.selected_media_count))
                .progressViewStyle(.linear)
                .padding(.horizontal)
        }
        .padding(.vertical, 25)
        .frame(maxWidth: 270)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
