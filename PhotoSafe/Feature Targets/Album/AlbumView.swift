//
//  ContentView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/25/25.
//
import SwiftUI

struct AlbumView: View {
    @StateObject private var album_VM = AlbumViewModel()
    @State private var display_alert: Bool = false
    @State private var path = NavigationPath()  // For NavigationStack
    @State private var password: String = ""
  
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                TopHeader(album_vm: self.album_VM)
                
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
                MediaView(album: album)
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
