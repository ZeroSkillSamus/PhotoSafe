//
//  CreateAlbumSheet.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/31/25.
//

import SwiftUI
import PhotosUI

enum KindOfTextBox {
    case Password
    case Name
}

struct CreateAlbumSheet: View {
    @EnvironmentObject private var album_vm: AlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var avatar: PhotosPickerItem?
    @State private var avatar_data: Data?
    @State private var name: String = ""
    @State private var password: String = ""

    @Binding var toggle_plus_mode: Bool
    
    func determine_if_button_disabled() -> Bool {
        self.name.isEmpty
    }
    
    private struct TextBox: View {
        var header: String
        var type: KindOfTextBox
        
        @Binding var text: String
        
        var body: some View {
            VStack(spacing: 5) {
                Text(header)
                    .font(.system(size: 18,weight: .semibold,design: .rounded))
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .foregroundStyle(Color.c1_text)
                
                TextField("", text: self.$text)
                    .fontWeight(.semibold)
                    .textInputAutocapitalization(type == .Name ? .words : .never)
                    .autocorrectionDisabled()
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    .foregroundStyle(.black)
                    .background(Color.c1_primary)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .onChange(of: self.text) {
                        // Check to see if its in character limit (15)
                        if text.count > 15 {
                            text.removeLast()
                        }
                    }
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.c1_secondary.ignoresSafeArea()
            
            VStack {
                Text("Create Album")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.c1_text)
                
                HStack {
                    PhotosPicker(
                        selection: $avatar,
                        matching: .images) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15).fill(.gray.opacity(0.5))
                                if let avatar_data, let ui_image = UIImage(data: avatar_data) {
                                    Image(uiImage: ui_image)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image("NoImageFound")
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                            .frame(width: 165, height:150)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        .frame(maxHeight: .infinity,alignment: .top)
                    
                    VStack {
                        TextBox(header: "Name", type: .Name, text: self.$name)
                        
                        TextBox(header: "Password", type: .Password, text: self.$password)
                        
                        Button {
                            self.album_vm.create_album(
                                name: self.name,
                                thumbnail: self.avatar_data,
                                password: self.password
                            )
                            
                            self.dismiss() // Close Sheet
                            withAnimation {
                                self.toggle_plus_mode.toggle()
                            }
                        } label: {
                            Text("Create")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .disabled(self.determine_if_button_disabled())
                        .buttonStyle(.borderedProminent)
                        .tint(Color.c1_secondary)
                        .buttonBorderShape(.roundedRectangle(radius: 10))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .top)
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity)
                .padding()
                .onChange(of: avatar) {
                    Task {
                        if let loaded = try? await avatar?.loadTransferable(type: Data.self) {
                            if let thumbnail_img = UIImage(data: loaded), let thumbnail_data = thumbnail_img.jpegData(compressionQuality: 0.5) {
                                avatar_data = thumbnail_data 
                            }
                        } else {
                            print("Failed")
                        }
                    }
                }
            }
            .padding(.top,25)
        }
        .presentationDetents([.medium, .fraction(0.35)])
    }
}
