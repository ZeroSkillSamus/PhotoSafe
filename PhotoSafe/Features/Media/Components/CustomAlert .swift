//
//  CustomAlert .swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/6/25.
//

import SwiftUI

struct CustomAlert_: View {
    @State private var test = 1.0
    
    var body: some View {
        ZStack {
            VStack {
                Text("Alert")
                    .font(.title.bold())
                
                ProgressView(value: self.test,total: 41.0)
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
            }
            .padding(.vertical, 25)
            .frame(maxWidth: 270)
            .background(BlurView(style: .systemMaterial))
            .cornerRadius(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//       .background(
//           Color.primary.opacity(0.35)
//       )
//       .edgesIgnoringSafeArea(.all)
    }
}
public struct BlurView: UIViewRepresentable {
    public var style: UIBlurEffect.Style

    public func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    CustomAlert_()
}
