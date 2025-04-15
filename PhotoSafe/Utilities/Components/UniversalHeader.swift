//
//  UniversalHeader.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/14/25.
//

import SwiftUI

struct UniversalHeader<Leading: View, Trailing: View>: View {
    let header: String
    
    @ViewBuilder let leading_button: Leading
    @ViewBuilder let trailing_button: Trailing
    
    var body: some View {
        HStack {
            leading_button
            
            Spacer()
            
            trailing_button
        }
        .frame(height:24)
        .padding(.horizontal)
        .padding(.vertical,10)
        .overlay(
            Text(header)
                .font(.title2.bold())
                .foregroundColor(.c1_text)
        )
        .background(Color.c1_secondary)
    }
}
