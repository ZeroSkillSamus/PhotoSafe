//
//  ContentView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/25/25.
//
import PhotosUI
import SwiftUI

enum KindOfTextBox {
    case Password
    case Name
}

struct CreateAlbum: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var avatar: PhotosPickerItem?
    @State private var avatar_data: Data?
    @State private var name: String = ""
    @State private var password: String = ""
    
    @ObservedObject var album_vm: AlbumViewModel
    
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
                
                TextField("", text: self.$text)
                    .fontWeight(.semibold)
                    .textInputAutocapitalization(type == .Name ? .words : .never)
                    .autocorrectionDisabled()
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    .foregroundStyle(.black)
                    .background(Color.primary)
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
                    TextBox(header: "Name", type: .Name, text: self.$name)
                    
                    TextBox(header: "Password", type: .Password, text: self.$password)

                    Button {
                        self.album_vm.create_album(
                            name: self.name,
                            image_data: self.avatar_data,
                            password: self.password
                        )
                        self.dismiss() // Close Sheet
                    } label: {
                        Text("Create")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .disabled(self.determine_if_button_disabled())
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
    @State private var display_delete_alert: Bool = false
    
    var body: some View {
        VStack(spacing:0) {
            HStack {
                // Display Alert Confirming With User
                // If they Want Albums to be removed
                Button {
                    self.display_delete_alert = true
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
                .font(.title2.bold())
                .foregroundColor(.primary)
        )
        .sheet(isPresented: self.$display_sheet) {
            CreateAlbum(album_vm: self.album_vm)
        }
        .alert("Delete All Albums?", isPresented: $display_delete_alert) {
            Button("Delete", role: .destructive) {
                withAnimation(.easeInOut) {
                    self.album_vm.delete_all_albums()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Will Delete All Albums & Media, Are you Sure????")
        }
    }
}

struct ContentView: View {
    @StateObject private var album_VM = AlbumViewModel()
    @State private var display_alert: Bool = false
    @State private var path = NavigationPath()  // For NavigationStack
    @State private var password: String = ""
  
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Header(album_vm: self.album_VM)
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(self.album_VM.albums, id:\.self) { album in
                            if album.is_locked {
                                Button {
                                    self.display_alert = true
                                } label: {
                                    AlbumDisplay(album: album)
                                }
                                .alert("Enter Password For \(album.name)",
                                       isPresented: self.$display_alert)
                                {
                                    TextField("Enter Your Password", text: self.$password)
                                        .foregroundStyle(.white)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                    
                                    Button("OK", role: .cancel) {
                                        if let album_password = album.password,
                                            album_password == password {
                                            path.append(album)
                                        }
                                    }
                                }
                            } else {
                                NavigationLink(value: album) {
                                    AlbumDisplay(album: album)
                                }
                            }
                            Divider()
                        }
                    }
                }
               
                // Ensure Everything Starts At Top of Page
                Spacer()
            }
            .navigationDestination(for: AlbumEntity.self) { album in
                MediaDisplay(album: album, album_vm: self.album_VM)
            }
        }
    }
    
    struct AlbumDisplay: View {
        var album: AlbumEntity

        var body: some View {
            HStack {
                VStack {
                    if let data = album.image, let ui_image = UIImage(data: data) {
                        Image(uiImage: ui_image)
                            .resizable()
                            .scaledToFill()
                        
                    } else {
                        Image("NoImageFound")
                            .resizable()
                            .scaledToFill()
                            //.frame(width: 100, height: 125)
                    }
                }
                .frame(width: 130, height:120)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                
                HStack {
                    Text(album.name)
                        .foregroundStyle(.white)
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
        }
    }
    
}

//#Preview {
//    ContentView().preferredColorScheme(.dark)
//}
