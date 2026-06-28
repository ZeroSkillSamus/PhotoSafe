//
//  ExportDestinationView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/29/26.
//

import SwiftUI

struct ExportDestinationView: View {
    @EnvironmentObject private var appSettings: AppSettingsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var customExportName: String = ""
    @State private var chosenOption: DestinationChoices = .photoslibrary
    
    @FocusState private var focusedField: Bool
    
    var body: some View {
        ZStack {
            Color.c1_secondary.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 15) {
                // Header
                VStack(spacing: 4) {
                    Text("Export Destination")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.c1_text)
                    
                    Text("Choose where exported photos and videos should go.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 14, design: .rounded))
                        .opacity(0.7)
                        .foregroundStyle(Color.c1_text)
                }
                
                // Choices
                ForEach(DestinationChoices.allCases) { choice in
                    VStack {
                        Text(choice.rawValue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 20, weight: .bold))
                        Text(choice.description)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 15, design: .rounded))
                    }
                    .padding()
                    .foregroundStyle(Color.c1_text)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.c1_accent).opacity(0.75))
                    .opacity(self.chosenOption == choice ? 1 : 0.3)
                    .animation(.easeInOut, value: choice == self.chosenOption)
                    .onTapGesture {
                        self.chosenOption = choice
                    }
                }
                
                VStack {
                    HStack {
                        Text("Album Name")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        //Spacer()
                        Text("\(self.customExportName.count)/24")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .opacity(0.75)
                    }
                    .foregroundStyle(Color.c1_text)
                    
                    TextField(
                        text: self.$customExportName,
                        prompt: Text("Type album name here...").foregroundStyle(Color.c1_text.opacity(0.8))
                    ) {
                        Text("Album Name") // Accessibility label
                    }
                    .focused(self.$focusedField)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .textFieldStyle(.plain)
                    .padding(12)
                    .truncationMode(.middle)
                    .foregroundStyle(Color.c1_text) // White typed text
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.c1_accent.opacity(0.75)) // 3. Applies the custom color
                    )
                    .padding(5)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.sentences)
                    .onChange(of: self.customExportName) { oldValue, newValue in
                        if newValue.count > 24 { customExportName = String(newValue.prefix(24)) }
                    }
                    .onSubmit {
                        focusedField = false
                    }
                }
                .disabled(self.chosenOption != .chosenAlbum)
                .opacity(self.chosenOption != .chosenAlbum ? 0.3 : 1)
                .animation(.easeInOut, value: self.chosenOption != .chosenAlbum)
                
                HStack {
                    // Save
                    Button {
                        switch self.chosenOption {
                        case .chosenAlbum:
                            let trimmed = customExportName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty { return }
                             
                            self.appSettings.exportAlbumName = trimmed
                            self.appSettings.exportDestination = DestinationChoices.chosenAlbum.rawValue
                        case .photoslibrary:
                            self.appSettings.exportDestination = DestinationChoices.photoslibrary.rawValue
                        }
                        
                        self.dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .padding(10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.c1_accent)
                    .buttonBorderShape(.roundedRectangle(radius: 10))
                    
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            .padding(.top,15)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            self.customExportName = self.appSettings.exportAlbumName
            self.chosenOption = DestinationChoices(rawValue: appSettings.exportDestination) ?? .photoslibrary
        }
        //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
