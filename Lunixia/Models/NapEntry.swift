//
//  NapEntry.swift
//  Lunixia
//

import Foundation
import SwiftData

@Model
final class NapEntry {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date = Date()
    var notes: String = ""
    var createdAt: Date = Date()

    var napCountToday: Int = 0
    var napMinutesToday: Int = 0
    var napCountThisWeek: Int = 0
    var averageNapLength: Double = 0

    init(
        startDate: Date = Date(),
        endDate: Date = Date(),
        notes: String = "",
        napCountToday: Int = 0,
        napMinutesToday: Int = 0,
        napCountThisWeek: Int = 0,
        averageNapLength: Double = 0
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.createdAt = Date()

        self.napCountToday = napCountToday
        self.napMinutesToday = napMinutesToday
        self.napCountThisWeek = napCountThisWeek
        self.averageNapLength = averageNapLength
    }

    var durationMinutes: Int {
        max(Int(endDate.timeIntervalSince(startDate) / 60), 0)
    }

    var durationHours: Double {
        Double(durationMinutes) / 60.0
    }

    var durationDisplay: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var averageNapLengthDisplay: String {
        let totalMinutes = Int(averageNapLength.rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m avg"
        } else if hours > 0 {
            return "\(hours)h avg"
        } else {
            return "\(minutes)m avg"
        }
    }
}
