//
//  LockScreen.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 3/26/25.
//

import SwiftUI

struct LockScreen: View {
    @State private var numberInput: String = ""
    
    var body: some View {
        VStack {
            // Title Of Page
            Text("Enter Password")
                .font(.title)
                .fontWeight(.semibold)
            
            // Create a Custom NumPad
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top)
    }
}

#Preview {
    LockScreen().preferredColorScheme(.dark)
}
