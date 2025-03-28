//
//  ContentView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/25/25.
//
import PhotosUI
import SwiftUI

struct CreateAlbum: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var avatar: PhotosPickerItem?
    @State private var avatar_data: Data?
    @State private var name: String = ""
    @State private var is_locked: Bool = false
    
    @ObservedObject var album_vm: AlbumViewModel
    
    var body: some View {
        VStack {
            Text("Create Album")
                .font(.title2)
                .fontWeight(.bold)
            
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
                    VStack(spacing: 5) {
                        Text("Enter Album Name")
                            .autocorrectionDisabled()
                            .font(.system(size: 15,weight: .semibold,design: .rounded))
                            .frame(maxWidth: .infinity,alignment: .leading)
                        
                        TextField("", text: $name)
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0))
                            .foregroundStyle(.black)
                            .background(Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .onChange(of: self.name) {
                                // Check to see if its in character limit (10)
                                if name.count > 10 {
                                    name.removeLast()
                                }
                            }
                    }
                    
                    Toggle(isOn: self.$is_locked) {
                        Text("Make Private")
                            .font(.system(size: 18,weight: .semibold,design: .rounded))
                    }
                    
                    Button {
                        self.album_vm.create_album(
                            name: self.name,
                            image_data: self.avatar_data,
                            is_locked: self.is_locked
                        )
                        self.dismiss() // Close Sheet
                    } label: {
                        Text("Create")
                            .font(.title3)
                            .fontWeight(.bold)
                            .disabled(self.name.isEmpty)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .buttonBorderShape(.roundedRectangle(radius: 10))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .top)
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .padding()
            .onChange(of: avatar) {
                Task {
                    if let loaded = try? await avatar?.loadTransferable(type: Data.self) {
                        avatar_data = loaded
                    } else {
                        print("Failed")
                    }
                }
            }
        }
        //.frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
        .padding(.top,25)
        .presentationDetents([.medium, .medium, .fraction(0.35)])
    }
}

struct Header: View {
    @ObservedObject var album_vm: AlbumViewModel
    
    @State private var display_sheet: Bool = false
    
    var body: some View {
        VStack(spacing:0) {
            HStack {
                // Display Alert Confirming With User
                // If they Want Albums to be removed
                Button {
                    self.album_vm.delete_all_albums()
                } label: {
                    Image(systemName:"trash.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // Created a menu for now
                // 1) Allow User To Create An Album
                Menu {
                    Button {
                        self.display_sheet.toggle()
                    } label: {
                        Label {
                            Text("New Album")
                        } icon: {
                            Image(systemName: "plus")
                        } 
                    }
                    
                    Button {
                        print("Edit")
                    } label: {
                        Label {
                            Text("Edit")
                        } icon: {
                            Image(systemName: "pencil")
                        }
                    }

                } label: {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .frame(height:24)
            .padding(.horizontal)
            .padding(.vertical,10)
        }
        .background(.bar)
        .overlay(
            Text("Albums")
                .font(.title3.bold())
                .foregroundColor(.primary)
        )
        .sheet(isPresented: self.$display_sheet) {
            CreateAlbum(album_vm: self.album_vm)
        }
    }
}

struct ContentView: View {
    @StateObject private var album_VM = AlbumViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            Header(album_vm: self.album_VM)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(self.album_VM.albums, id:\.self) { album in
                        HStack {
                            if let data = album.image, let ui_image = UIImage(data: data) {
                                Image(uiImage: ui_image)
                                    .resizable()
                                    .frame(width: 100, height: 125)
                                
                            } else {
                                Image("NoImageFound")
                                    .resizable()
                                    .frame(width: 100, height: 125)
                            }
                            
                            HStack {
                                Text(album.name!)
                                    .padding(.leading,20)
                                    .font(.system(size: 18,weight: .medium,design: .rounded))
                                
                                Spacer()
                                
                                if album.is_locked {
                                    Image(systemName: "lock.fill")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                        .padding(.trailing,20)
                                }
                            }
                            .frame(maxWidth:.infinity)
                            
                            
                        }
                        Divider()
                    }
                }
            }
            
            // Ensure Everything Starts At Top of Page
            Spacer()
        }
    }
}

#Preview {
    ContentView().preferredColorScheme(.dark)
}
