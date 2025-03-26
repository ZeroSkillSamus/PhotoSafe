//
//  ContentView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/25/25.
//

import SwiftUI

struct Header: View {
    var body: some View {
        VStack(spacing:0) {
            HStack {
                // Display Alert Confirming With User
                // If they Want Albums to be removed
                Button {
                   print("Delete All")
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
                        print("Create")
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
        #if os(iOS)
            .background(.bar)
        #endif
        .overlay(
            Text("Albums")
                .font(.title3.bold())
                .foregroundColor(.primary)
        )
    }
}

// Create Dummy Data
struct Album: Hashable {
    var is_locked: Bool
    var name: String
    var image: String
}

var dummydata = [
    Album(is_locked: true, name: "TEST1", image: ""),
    Album(is_locked: true, name: "TEST2", image: ""),
    Album(is_locked: false, name: "TEST3", image: ""),
    Album(is_locked: false, name: "TEST4", image: "")
]


struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            Header()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(dummydata, id:\.self) { album in
                        HStack {
                            AsyncImage(url: URL(string: "https://picsum.photos/id/237/400/400")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 80, height: 95)
   
                            HStack {
                                Text(album.name)
                                    .padding(.leading,20)
                                
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
    ContentView()
}
