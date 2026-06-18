//
//  ToastItem.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import Foundation

enum Status: String {
    case success
    case failure
}

struct ToastItem {
    let message: String
    let status: Status
}
