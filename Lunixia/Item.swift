//
//  Item.swift
//  Lunixia
//
//  Created by Asteria Moon on 5/20/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
