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
                Button {
                   print("Hi")
                } label: {
                    Image(systemName:"trash.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }

                
                Spacer()
                
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

struct ContentView: View {
    var body: some View {
        VStack {
            Header()
            Spacer()
            
        }
        //.padding()
    }
}

#Preview {
    ContentView()
}
