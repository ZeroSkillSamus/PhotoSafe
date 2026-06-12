//
//  WebVavigationBar.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import SwiftUI

struct WebVavigationBar: View {
    var webViewModel: WebViewModel
    @State private var userInputText: String = ""
    @State private var userSubmitedText: String = ""
    
    var body: some View {
        HStack {
            Button {
                webViewModel.goBack()
            } label: {
                Image(systemName: "chevron.backward")
            }
            .opacity(!webViewModel.canGoBack ? 0.55 : 1)
            .foregroundStyle(Color.c1_accent)
            .disabled(!webViewModel.canGoBack)
            
            
            Button {
                webViewModel.goForward()
            } label: {
                Image(systemName: "chevron.forward")
            }
            .opacity(!webViewModel.canGoFoward ? 0.55 : 1)
            .foregroundStyle(Color.c1_accent)
            .disabled(!webViewModel.canGoFoward)
            
            TextField("Enter url here...", text: self.$userInputText)
                .textFieldStyle(.plain)
                .padding(6)
                .truncationMode(.middle)
                .background(Color.white.opacity(0.75))
                .cornerRadius(8)
                .foregroundStyle(Color.c1_accent)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    self.userSubmitedText = self.userInputText
                    
                    self.webViewModel.update(url: URL(string: userSubmitedText))
                    self.webViewModel.userNavigateTo(urlString: userSubmitedText)
                }
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            Button {
                webViewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .foregroundStyle(Color.c1_accent)
        }
        .frame(height:24)
        .padding(.horizontal)
        .padding(.vertical,10)
        .background(Color.c1_secondary)
        .onAppear {
            self.userInputText = self.webViewModel.currentUrl?.absoluteString ?? ""
        }
        .onChange(of: webViewModel.currentUrl) { oldValue, newValue in
            self.userInputText = newValue?.absoluteString ?? ""
        }
        .overlay(alignment: .bottom) {
            if webViewModel.isLoading {
                ProgressView(value: webViewModel.progress, total: 1.0)
                    .tint(Color.c1_primary)
            }
        }
    }
}
