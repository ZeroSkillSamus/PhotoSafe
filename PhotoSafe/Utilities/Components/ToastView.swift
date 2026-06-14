//
//  ToastView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/14/26.
//
//
//import SwiftUI
//
//struct ToastView: View {
//    @Binding let message: String
//    
//    var body: some View {
//        Text(message)
//                     .font(.system(size: 14, weight: .medium, design: .rounded))
//                     .foregroundStyle(.white)
//                     .padding(.horizontal, 16)
//                     .padding(.vertical, 10)
//                     .background(message.starts(with: "Failed") == true ? Color.red.opacity(0.85) : Color.black.opacity(0.75))
//                     .clipShape(Capsule())
//                     .padding(.bottom, 12)
//                     .transition(.move(edge: .bottom).combined(with: .opacity))
//                     .onAppear {
//                         DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
//                             withAnimation { self.message = nil }
//                         }
//                     }
//    }
//}
