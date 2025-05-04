//
//  UniversalHeader.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/14/25.
//

import SwiftUI

struct UniversalHeader<Header: View, Leading: View, Trailing: View>: View {
    @ViewBuilder var header: Header
    
    @ViewBuilder var leading_button: Leading
    @ViewBuilder var trailing_button: Trailing
    
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
            header
        )
        .background(Color.c1_secondary)
    }
}

extension Text {
    func default_header() -> Self {
        self
            .font(.title2.bold())
            .foregroundColor(.c1_text)
    }
}
