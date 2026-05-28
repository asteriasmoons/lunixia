//
// DailyIntention.swift
// Lunixia
//

import Foundation
import SwiftData

@Model
final class DailyIntention {

    var dateKey: String = ""

    var date: Date = Date()
    var text: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(date: Date = Date(), text: String = "") {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let normalized = cal.date(from: comps) ?? date

        self.date = normalized

        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        self.dateKey = formatter.string(from: normalized)
        self.text = text
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
