//
//  CreateFolderSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import SwiftUI

struct CreateFolderSheet: View {
    @Environment(\.dismiss) var dismiss

    var folderBookmarkViewModel: FolderBookmarkViewModel
    @Binding var toast: ToastItem?

    @FocusState private var isFocused: Bool
    @State private var userTitle: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                HStack {
                    Button {
                        self.dismiss()
                    } label: {
                        Text("X")
                            .font(.system(size: 20, design: .rounded))
                            .padding(15)
                            .foregroundStyle(.red)
                    }
                    .applyLiquidGlassIfSupported(shape: .circle)

                    Spacer()

                    Button {
                        toast = folderBookmarkViewModel.addFolder(name: self.userTitle)
                        self.dismiss()
                    } label: {
                        Text("Create")
                            .font(.system(size: 20, design: .rounded))
                            .padding(10)
                            .foregroundStyle(Color.c1_text)
                    }
                    .applyLiquidGlassIfSupported()
                }
                .overlay(alignment: .center) {
                    Text("Create Folder")
                        .font(.system(size: 20,weight: .semibold,design: .rounded))
                        .foregroundStyle(Color.c1_text)
                }

                HStack {
                    TextField(
                        "",
                        text: $userTitle,
                        prompt: Text("Enter Folder Name Here...").foregroundStyle(Color.c1_text)
                    )
                    .focused($isFocused)
                    .foregroundStyle(Color.c1_text)
                    .font(.system(size: 16,design: .rounded))
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 25).foregroundStyle(Color.c1_accent))

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding()
        .background(Color.c1_background)
        .task {
            self.isFocused = true
        }
    }
}
