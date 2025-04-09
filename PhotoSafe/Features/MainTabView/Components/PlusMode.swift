//
//  PlusMode.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import SwiftUI
import PhotosUI

struct PlusMode: View {
    @StateObject private var media_VM: MediaViewModel = MediaViewModel()
    
    @State private var selected_media: [PhotosPickerItem] = []
    @State private var create_album_sheet: Bool = false
    @State private var show_move_sheet: Bool = false
 
    @Binding var toggle_plus_mode: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 25) {
                PhotosPicker(
                    selection: self.$selected_media,
                    selectionBehavior: .ordered,
                    photoLibrary: .shared()
                ) {
                    VStack {
                        ImageCircleOverlay(
                            icon: ImageCircleOverlay.IconType.symbol("photo.badge.plus"),
                            frame: CGSize(width: 60, height: 60)
                        )

                        Text("Import Photos")
                            .foregroundStyle(.white)
                            .font(.caption.bold())
                            .frame(width: 50)
                    }
                }

                Button {
                    self.create_album_sheet.toggle()
                } label: {
                    VStack {
                        ImageCircleOverlay(
                            icon: ImageCircleOverlay.IconType.symbol("rectangle.stack.fill.badge.plus"),
                            frame: CGSize(width: 60, height: 60)
                        )

                        Text("New Album")
                            .foregroundStyle(.white)
                            .font(.caption.bold())
                            .frame(width: 50)
                    }
                }
                .sheet(isPresented: self.$create_album_sheet) {
                    CreateAlbumSheet(toggle_plus_mode: self.$toggle_plus_mode)
                }
            }
            
            Button {
                withAnimation(.easeInOut) {
                    self.toggle_plus_mode.toggle()
                }
                
            } label: {
                ImageCircleOverlay(
                    color: .red,
                    icon: ImageCircleOverlay.IconType.text("X")
                )
            }
        }
        .sheet(isPresented: self.$show_move_sheet) {
            MoveSheet(media_VM: self.media_VM) { album in
                Task {
                    await self.media_VM.add_imported_photos(to: album, from: self.selected_media)
                    
                    // Done Looping, Time to Clear Out SelectedMedia
                    self.selected_media.removeAll()
                }
            }
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .bottom)
        .background(Color(red: 28/255, green: 28/255, blue: 30/255).opacity(0.75))
        .opacity(self.toggle_plus_mode ? 1 : 0)
        .onTapGesture {
            withAnimation {
                self.toggle_plus_mode.toggle()
            }
        }
        .overlay {
            if self.media_VM.progress_alert {
                ProgressAlert(
                    selected_media_count: self.selected_media.count,
                    alert_value: self.media_VM.alert_value
                )
            }
        }
        .onChange(of: self.selected_media) {
            if !selected_media.isEmpty {
                self.toggle_plus_mode.toggle()
                
                // Delay the move sheet mode toggle by 0.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.show_move_sheet.toggle()
                }
            }
        }
    }
}
