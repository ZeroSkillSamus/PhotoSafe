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

enum Field {
    case albumName
    case password
    case confirmPassword
}

struct CreateAlbumSection<Content: View, Header: View>: View {
    var field: Field
    var icon: String
    
    @ViewBuilder var header: Header
    @ViewBuilder var textField: Content
    
    var body: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.c1_background.opacity(0.7))
                
                textField
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.7))
            .cornerRadius(18)
        } header: {
            header
        }
    }
}

struct CreateAlbumSheet: View {
    var maxAlbumNameLength: Int = 24
    
    @EnvironmentObject private var albumViewModel: AlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var avatar: PhotosPickerItem?
    @State private var thumbnailData: Data?
    
    @State private var albumName: String = ""
    @State private var albumPassword: String = ""
    @State private var confirmAlbumPassword: String = ""
    @State private var isPasswordRevealed: Bool = false
    @State private var toast: ToastItem?
    
    
    @FocusState private var focusedField: Field? 
    
    @Binding var isPlusModeActive: Bool
    var header: String = "Create Album"
    var moveAction: ((String) -> Void)? = nil
    
    var hasChanges: Bool {
        let trimmedName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            // Only specify albumname
            if albumPassword.isEmpty && confirmAlbumPassword.isEmpty { return true }
            
            if !albumPassword.isEmpty && !confirmAlbumPassword.isEmpty {
                return albumPassword == confirmAlbumPassword
            }
        }
        
        return false
    }
    
    @ViewBuilder
    func textFieldSwitch(
        text: Binding<String>,
        prompt: String,
        focusField: Field
    ) -> some View {
        if isPasswordRevealed {
            TextField(
                "",
                text: text,
                prompt: Text(prompt)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.c1_background.opacity(0.75))
            )
            .focused($focusedField, equals: focusField)
            .textFieldStyle(.plain)
            .foregroundStyle(Color.c1_background)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        } else {
            SecureField(
                "",
                text: text,
                prompt: Text(prompt)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.c1_background.opacity(0.75))
            )
            .focused($focusedField, equals: focusField)
            .textFieldStyle(.plain)
            .foregroundStyle(Color.c1_background)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Image
            PhotosPicker(
                selection: $avatar,
                matching: .images
            ) {
                ZStack {
                    if !albumPassword.isEmpty {
                        // Show lock
                        RoundedRectangle(cornerRadius: 20).fill(Color.c1_secondary)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 50, weight: .semibold))

                            Text("Album is locked when password is specefied")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                            
                            Text("A lock image will be shown when locked")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .opacity(0.7)
                        }
                        .foregroundStyle(Color.c1_text)
                        .multilineTextAlignment(.center)
                        .padding()
                        
                    } else {
                        if let thumbnailData, let image = UIImage(data: thumbnailData) {
                            Image(uiImage: image)
                                .resizable()
                                //.scaledToFill()
                        } else {
                            RoundedRectangle(cornerRadius: 20).fill(Color.c1_secondary)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 50, weight: .semibold))

                                Text("Set album cover")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))

                                Text("Optional")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .opacity(0.7)
                            }
                            .foregroundStyle(Color.c1_text)
                            .multilineTextAlignment(.center)
                            .padding()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .clipped()
                .contentShape(Rectangle())
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.55), .clear, .black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        if !self.albumName.isEmpty {
                            Text(albumName.trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.system(size: 25,weight: .semibold))
                                .frame(maxWidth: .infinity,alignment: .leading)
                                .foregroundStyle(Color.c1_text)
                        }
                        
                        Text("Cover Preview")
                            .font(.system(size: 20,weight: .semibold))
                            .frame(maxWidth: .infinity,alignment: .leading)
                            .foregroundStyle(Color.c1_text)
                            .opacity(0.7)
                        
                    }
                    .frame(maxWidth: .infinity)
                    .padding(5)
                    .padding(.horizontal,6)
                    .padding(.bottom,40)
                    
                }
            }
            .frame(height: 420)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .top)
            .disabled(!self.albumPassword.isEmpty)
            
            // Header
            HStack {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20,weight: .semibold))
                        .foregroundStyle(Color.c1_text)
                        .padding(10)
                        .applyLiquidGlassIfSupported(shape: .circle, color: Color.c1_accent)
                }
                Spacer()
            }
            .overlay(alignment: .center) {
                Text(header)
                    .font(.system(size: 24,weight: .bold,design: .rounded))
                    .foregroundStyle(Color.c1_text)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            
            VStack {
                Color.clear
                    .frame(height: 320)
                
                VStack(spacing: 14) {
                    CreateAlbumSection(
                        field: .albumName,
                        icon: "rectangle.stack.fill",
                        header: {
                            Text("Album Name")
                                .font(.system(size: 17,weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity,alignment: .leading)
                                .foregroundStyle(Color.c1_text)
                                .opacity(0.8)
                        },
                        textField: {
                            TextField(
                                "",
                                text: self.$albumName,
                                prompt: Text("Enter album name")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.c1_background.opacity(0.75))
                            )
                            .textFieldStyle(.plain)
                            .foregroundStyle(Color.c1_background)
                            .focused($focusedField, equals: .albumName)
                            .onSubmit { self.focusedField = .password }
                            
                            Text("\(albumName.count)/\(maxAlbumNameLength)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.c1_background.opacity(0.7))
                        }
                    )
                    .onChange(of: self.albumName) { oldValue, newValue in
                        if newValue.count > maxAlbumNameLength {
                            albumName = String(newValue.prefix(maxAlbumNameLength))
                        }
                    }
                    
                    CreateAlbumSection(
                        //isPasswordRevealed: self.$isPasswordRevealed,
                        field: .password,
                        icon: "lock.fill",
                        header: {
                            HStack(spacing: 10) {
                                Text("Password")
                                    .font(.system(size: 17,weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.c1_text)
                                    .opacity(0.8)
                                Text("Optional")
                                    .font(.system(size: 14,weight: .bold))
                                    .italic(true)
                                    .foregroundStyle(Color.c1_text)
                                    .opacity(0.7)
                            }
                            .frame(maxWidth: .infinity,alignment: .leading)
                        },
                        textField: {
                            textFieldSwitch(
                                text: self.$albumPassword,
                                prompt: "Enter password",
                                focusField: .password
                            )
                            .onSubmit { self.focusedField = .confirmPassword }
                            
                            Button {
                                self.isPasswordRevealed.toggle()
                            } label: {
                                Image(systemName: self.isPasswordRevealed ? "eye.slash" : "eye")
                                    .foregroundStyle(Color.c1_background)
                            }
                        }
                    )
                    .onChange(of: self.albumPassword) { oldValue, newValue in
                        if newValue.isEmpty { self.confirmAlbumPassword = "" }
                    }
                    
                    Group {
                        if albumPassword.isEmpty {
                            Text("Adding a password locks this album.")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.c1_text)
                                .opacity(0.8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                        } else {
                            Text("PhotoSafe cannot recover album passwords. Store it somewhere safe.")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.c1_text)
                                .opacity(0.8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    CreateAlbumSection(
                        field: .confirmPassword,
                        icon: "checkmark.shield.fill",
                        header: {
                            Text("Confirm Password")
                                .font(.system(size: 17,weight: .bold, design: .rounded))
                                .foregroundStyle(Color.c1_text)
                                .opacity(0.8)
                                .frame(maxWidth: .infinity,alignment: .leading)
                        },
                        textField: {
                            textFieldSwitch(
                                text: self.$confirmAlbumPassword,
                                prompt: "Confirm password",
                                focusField: .confirmPassword
                            )
                            .onSubmit { self.focusedField = nil }
                            
                            Button {
                                self.isPasswordRevealed.toggle()
                            } label: {
                                Image(systemName: self.isPasswordRevealed ? "eye.slash" : "eye")
                                    .foregroundStyle(Color.c1_background)
                            }
                        }
                    )
                    .opacity(!albumPassword.isEmpty ? 1 : 0)
                    
                    
                    Spacer()
                    
                    Button {
                        do {
                            let trimmedName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            try self.albumViewModel.create_album(
                                name: trimmedName,
                                thumbnail: self.thumbnailData,
                                password: self.albumPassword
                            )
                            
                            self.dismiss() // Close Sheet
                            
                            if let moveAction {
                                moveAction(self.albumName)
                            }
//                            withAnimation {
//                                self.isPlusModeActive.toggle()
//                            }
                        } catch (let error) {
                            self.toast = ToastItem(message: error.localizedDescription, status: .failure)
                        }
                        
                    } label: {
                        Text(self.header)
                            .padding(5)
                            .font(.system(size: 19,weight: .semibold))
                            .foregroundStyle(Color.c1_text)
                            .padding()
                            .applyLiquidGlassIfSupported(color: Color.c1_secondary,isInteractive: true)
                    }
                    .padding(.bottom,30)
                    .opacity(hasChanges ? 1 : 0.3)
                    .disabled(!hasChanges)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .background(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]).fill(Color.c1_accent))
                .ignoresSafeArea(edges: .bottom)
                .animation(.easeInOut, value: !albumPassword.isEmpty)
                
            }
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .onChange(of: avatar) { old, new in
            Task {
                guard let new else {
                    self.avatar = old
                    self.toast = ToastItem(message: "Failed to fetch cover photo", status: .failure)
                    return
                }
                
                do {
                    guard let loadedData = try await new.loadTransferable(type: Data.self) else {
                        return
                    }
                    
                    guard let thumbnailImage = UIImage(data: loadedData), let data = thumbnailImage.jpegData(compressionQuality: 0.5) else {
                        return
                    }
                    
                    self.thumbnailData = data
                } catch {
                    // Toast
                    self.avatar = old
                    self.toast = ToastItem(message: "Failed to fetch cover photo", status: .failure)
                }
            }
        }
        .orientationLock(.portrait)
        .displayToast(self.$toast)
    }
}

//#Preview {
//    CreateAlbumSheet()
//}

/// A custom SwiftUI `Shape` that applies rounded corners to specific corners of a rectangle.
/// This is useful when you need to round only certain corners (e.g., top-left + top-right)
/// unlike SwiftUI's built-in `.cornerRadius()` which rounds all corners uniformly.
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    
    /// The corners to round, specified as a `UIRectCorner` option set.
    /// Defaults to `.allCorners` (behaves like `.cornerRadius`).
    var corners: UIRectCorner = .allCorners

    /// Creates a `Path` with rounded corners for the given rectangle.
    /// - Parameter rect: The rectangle to round.
    /// - Returns: A `Path` with the specified corners rounded.
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
