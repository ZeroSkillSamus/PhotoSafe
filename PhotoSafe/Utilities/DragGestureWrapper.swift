//
//  DragGestureWrapper.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/7/25.
//

import SwiftUI

struct DragGestureWrapper<Content: View>: View {
    @State private var tapLocation: CGPoint = .zero
    @State private var dragHeight: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var anchor: UnitPoint = .center

    let content: () -> Content
    let dismissAction: () -> Void  // Add dismiss action parameter
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 25)
            .onChanged { value in
                // Only allow vertical dragging when not zoomed
                //if abs(value.translation.height) > abs(value.translation.width) {
                    // Only allow downward swipes
                    if value.translation.height > 0 {
                        dragHeight = value.translation.height
                    }
                //}
            }
            .onEnded { value in
                withAnimation(.interactiveSpring()) {
                    if dragHeight > 100 {
                        self.dismissAction()
                    } else {
                        dragHeight = 0
                    }
                }
            }
    }

    var body: some View {
        GeometryReader { geometry in
            content()
                .offset(y: dragHeight)
                .scaleEffect(scale, anchor: anchor)
                .gesture(
                    dragGesture
//                    SpatialTapGesture(count: 2)
//                        .onEnded { event in
//                            // Get the tap location in the image's coordinate space
//                            let imageFrame = geometry.frame(in: .local)
//                            let tapLocationInImage = CGPoint(
//                                x: event.location.x - imageFrame.origin.x,
//                                y: event.location.y - imageFrame.origin.y
//                            )
//
//                            // Convert to normalized coordinates (0-1)
//                            let normalizedX = tapLocationInImage.x / imageFrame.width
//                            let normalizedY = tapLocationInImage.y / imageFrame.height
//
//                            if scale == 1.0 {
//                                withAnimation(.interactiveSpring()) {
//                                    scale = 3.0
//                                    anchor = UnitPoint(x: normalizedX, y: normalizedY)
//                                }
//                            } else {
//                                withAnimation(.interactiveSpring()) {
//                                    scale = 1.0
//                                    anchor = .center
//                                }
//                            }
//                        }
//                        .simultaneously(with: dragGesture) // Combine with other gestures
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .center)
        }
    }
}
