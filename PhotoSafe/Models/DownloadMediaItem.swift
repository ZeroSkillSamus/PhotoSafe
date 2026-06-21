//
//  DownloadMediaItem.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/12/26.
//

import SwiftUI

struct DownloadMediaItem: Hashable {
    let id: UUID
    let url: String
    //var status: Status
    var downloadedAt: Date
    var albumDownloadedTo: String
    var domain: String?
    var thumbnail: Data?
    
    var thumbnailImage: UIImage? {
        guard let thumbnail else { return nil }
        return UIImage(data: thumbnail)
    }
    
    var timeSinceCreated: Text {
        let today = Date()
        let components = Calendar.current.dateComponents([.day, .month, .hour, .year, .minute, .second, .weekday], from: today, to: downloadedAt)

        if let year = components.year, year < 0 {
            return Text(downloadedAt.formatted(date: .abbreviated, time: .shortened))
        } else if let month = components.month, month < 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return Text(formatter.string(from: downloadedAt))
        } else if let day = components.day, day < 0 {
            return Text("^[\(abs(day)) day](inflect: true) ago")
        } else if let hour = components.hour, hour < 0 {
            return Text("^[\(abs(hour)) hour](inflect: true) ago")
        } else if let minute = components.minute, minute < 0 {
            return Text("^[\(abs(minute)) min](inflect: true) ago")
        } else if let second = components.second, second < 0 {
            return Text("^[\(abs(second)) sec](inflect: true) ago")
        }
        return Text("")
    }
}
