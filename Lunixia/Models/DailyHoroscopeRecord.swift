//
//  DailyHoroscopeRecord.swift
//  Lunixia
//

import Foundation
import SwiftData

@Model
final class DailyHoroscopeRecord {
    var dayKey: String = ""
    var sign: String = ""
    var message: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        dayKey: String,
        sign: String,
        message: String
    ) {
        self.dayKey = dayKey
        self.sign = sign
        self.message = message
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
