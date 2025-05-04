//
//  ProgressAlertView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/14/25.
//

import SwiftUI

struct ProgressAlert: View {
    var selected_media_count: Int
    var alert_value: Float
    
    var body: some View {
        CustomAlertView {
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
    }
}
