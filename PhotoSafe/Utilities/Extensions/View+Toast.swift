//
//  View+Toast.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/23/26.
//

import SwiftUI

extension View {
    func displayToast(_ toast: Binding<ToastItem?>) -> some View {
        self.modifier(ToastModifer(toastItem: toast))
    }
}
