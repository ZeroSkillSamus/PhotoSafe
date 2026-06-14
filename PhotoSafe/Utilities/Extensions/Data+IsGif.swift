//
//  Data+IsGif.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/14/26.
//

import SwiftUI

extension Data {
    var isGIF: Bool {
        // A GIF header requires at least 3 bytes ("GIF")
        guard self.count > 3 else { return false }
        
        // Extract the first 3 bytes safely
        let bytes = [UInt8](self.prefix(3))
        
        // ASCII values: 'g' = 0x67 or 103, 'i' = 0x69 or 105, 'f' = 0x66 or 102
        // Case-insensitive check for "GIF" or "gif"
        let isMatch = (bytes[0] == 103 || bytes[0] == 71) && // g or G
                      (bytes[1] == 105 || bytes[1] == 73) && // i or I
                      (bytes[2] == 106 || bytes[2] == 70)    // f or F
        
        return isMatch
    }
}
