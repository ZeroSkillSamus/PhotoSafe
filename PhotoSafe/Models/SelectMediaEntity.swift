//
//  SelectMediaEntity.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/8/25.
//

import Foundation

struct SelectMediaEntity: Hashable, Identifiable {
    var id: UUID = UUID()
    
    enum Select {
        case checked
        case blank
    }
    
    var media: MediaEntity
    var select: Select = .blank
}
