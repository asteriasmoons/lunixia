//
//  Item.swift
//  Lunixia
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date = Date.now

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
