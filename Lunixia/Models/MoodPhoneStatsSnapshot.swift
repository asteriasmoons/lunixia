//
//  MoodPhoneStatsSnapshot.swift
//  Lunixia
//

import Foundation
import SwiftData

@Model
final class MoodPhoneStatsSnapshot {

    // MARK: - Identity

    var id: UUID = UUID()
    var date: Date = Date()

    // MARK: - Phone Behavior Totals

    var screenTimeMinutes: Double = 0
    var socialAppMinutes: Double = 0
    var nighttimePhoneMinutes: Double = 0

    // MARK: - Interruption / Checking Behavior

    var pickupCount: Int = 0
    var notificationCount: Int = 0

    // MARK: - Mood Link

    var averageMoodScore: Double = 0
    var moodCheckInCount: Int = 0
    var mostCommonMoodTitle: String = ""
    var mostCommonMoodIcon: String = ""

    // MARK: - Metadata

    var source: String = "deviceActivity"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        screenTimeMinutes: Double = 0,
        socialAppMinutes: Double = 0,
        nighttimePhoneMinutes: Double = 0,
        pickupCount: Int = 0,
        notificationCount: Int = 0,
        averageMoodScore: Double = 0,
        moodCheckInCount: Int = 0,
        mostCommonMoodTitle: String = "",
        mostCommonMoodIcon: String = "",
        source: String = "deviceActivity",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.screenTimeMinutes = screenTimeMinutes
        self.socialAppMinutes = socialAppMinutes
        self.nighttimePhoneMinutes = nighttimePhoneMinutes
        self.pickupCount = pickupCount
        self.notificationCount = notificationCount
        self.averageMoodScore = averageMoodScore
        self.moodCheckInCount = moodCheckInCount
        self.mostCommonMoodTitle = mostCommonMoodTitle
        self.mostCommonMoodIcon = mostCommonMoodIcon
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
