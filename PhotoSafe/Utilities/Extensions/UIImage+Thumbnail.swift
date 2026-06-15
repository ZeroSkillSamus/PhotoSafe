//
//  Untitled.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/15/26.
//

import SwiftUI

extension UIImage {
    func thumbnail(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        let imageRenderer = UIGraphicsImageRenderer(size: size)
        return imageRenderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
