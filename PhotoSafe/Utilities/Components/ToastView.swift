//
//  ToastView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/14/26.
//
//
import SwiftUI

struct ToastModifer: ViewModifier {
    @Binding var toastItem: ToastItem?
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                VStack {
                    Spacer()
                    mainToastView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(.bottom,25)
            }
    }
    
    /// Dismisses the current toast and cleans up resources
    /// - Note: Animates the dismissal and cancels any pending work items
    private func dismissToast() {
        withAnimation {
            toastItem = nil
        }
    }
    
    /// Displays the current toast and sets up automatic dismissal if needed
    /// - Note: Triggers haptic feedback when toast is shown
    private func showToast() {
        if toastItem == nil { return }
        #if os(iOS)
        // Provide haptic feedback
        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: dismissToast)
    }
    
    /// Constructs the main toast view if a toast is present
    /// - Returns: The toast view or an empty view
    @ViewBuilder func mainToastView() -> some View {
        if let toastItem {
            ToastView(
                toastItem: toastItem
            )
            .onAppear {
                showToast()
            }
        }
    }
}

struct ToastView: View {
    var toastItem: ToastItem
    
    var body: some View {
        Text(toastItem.message)
             .font(.system(size: 14, weight: .medium, design: .rounded))
             .foregroundStyle(Color.c1_text)
             .padding(.horizontal, 16)
             .padding(.vertical, 10)
             .background(toastItem.status == .failure ? Color.red.opacity(0.85) : Color.c1_accent.opacity(0.75))
             .clipShape(Capsule())
             .padding(.bottom, 12)
             .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
