//
//  SettingsRowView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/29/26.
//

import SwiftUI

struct SettingsSectionView<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var header: String
    var backgroundColor: Color = Color.c1_accent
    
    var body: some View {
        Section {
            VStack {
                content()
            }
            .background(RoundedRectangle(cornerRadius: 15).fill(backgroundColor).opacity(0.75))
        } header: {
            Text(header)
                .font(.system(size: 20,weight: .semibold,design: .rounded))
                .foregroundStyle(Color.c1_text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SettingsRowView<Trailing: View, Overlay: View>: View {
    var icon: String
    var title: String
    var subtitle: String?
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var overlay: () -> Overlay
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20,weight: .semibold,design: .rounded))
                .foregroundStyle(Color.c1_text)
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.c1_primary.opacity(0.1)))
            
            VStack {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16,weight: .semibold,design: .rounded))
                
                if let subtitle {
                    Text(subtitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 13,weight: .regular,design: .rounded))
                        .opacity(0.7)
                }
            }
            .padding(.horizontal,7)
            .foregroundStyle(Color.c1_text)
            .frame(maxWidth: .infinity)
            
            trailing()
        }
        .overlay(alignment: .trailing) {
            overlay()
        }
        .padding(.horizontal,5)
        .padding(10)
    }
}
