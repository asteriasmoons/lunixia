//
//  SelfCareModels.swift
//  Lunixia
//

import Foundation
import SwiftData

// MARK: - Source Type

enum LunixiaPointSourceType: String, Codable, CaseIterable {
    case journalEntry    = "journalEntry"
    case moodLog         = "moodLog"
    case vitalsLog       = "vitalsLog"
    case exerciseLog     = "exerciseLog"
    case medicationTaken = "medicationTaken"
    case waterLog        = "waterLog"
    case waterGoal       = "waterGoal"
    case stepGoal        = "stepGoal"
    case dailyIntention  = "dailyIntention"

    var label: String {
        switch self {
        case .journalEntry:    return "Journal Entry"
        case .moodLog:         return "Mood Log"
        case .vitalsLog:       return "Vitals Log"
        case .exerciseLog:     return "Exercise Log"
        case .medicationTaken: return "Medication Taken"
        case .waterLog:        return "Water Logged"
        case .waterGoal:       return "Water Goal Reached"
        case .stepGoal:        return "Step Goal Reached"
        case .dailyIntention:  return "Daily Intention"
        }
    }

    var asset: String {
        switch self {
        case .journalEntry:    return "lovejournal"
        case .moodLog:         return "xsmile"
        case .vitalsLog:       return "heartpulse"
        case .exerciseLog:     return "health"
        case .medicationTaken: return "pilldrop"
        case .waterLog:        return "drops"
        case .waterGoal:       return "drops"
        case .stepGoal:        return "health"
        case .dailyIntention:  return "starfill"
        }
    }
}

// MARK: - Point Entry

@Model
final class LunixiaPointEntry {
    var id: UUID = UUID()
    var userId: String = ""
    var sourceTypeRaw: String = LunixiaPointSourceType.journalEntry.rawValue
    var sourceId: String?
    var sourceKey: String = ""
    var dayKey: String = ""
    var points: Int = 0
    var title: String = ""
    var details: String?
    var createdAt: Date = Date()

    var sourceType: LunixiaPointSourceType {
        get { LunixiaPointSourceType(rawValue: sourceTypeRaw) ?? .journalEntry }
        set { sourceTypeRaw = newValue.rawValue }
    }

    init(
        userId: String = "",
        sourceType: LunixiaPointSourceType = .journalEntry,
        sourceId: String? = nil,
        sourceKey: String = "",
        dayKey: String = "",
        points: Int = 0,
        title: String = "",
        details: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.userId = userId
        self.sourceTypeRaw = sourceType.rawValue
        self.sourceId = sourceId
        self.sourceKey = sourceKey
        self.dayKey = dayKey
        self.points = max(0, points)
        self.title = title
        self.details = details
        self.createdAt = createdAt
    }
}

// MARK: - Points Profile

@Model
final class LunixiaPointsProfile {
    var id: UUID = UUID()
    var userId: String = ""
    var currentPoints: Int = 0
    var lifetimePoints: Int = 0
    var spentPoints: Int = 0
    var level: Int = 0
    var lastEarnedAt: Date? = nil
    var lastWeeklyResetAt: Date? = nil
    var currentWeekStartDayKey: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(userId: String = "", currentWeekStartDayKey: String = "") {
        self.id = UUID()
        self.userId = userId
        self.currentPoints = 0
        self.lifetimePoints = 0
        self.spentPoints = 0
        self.level = 0
        self.currentWeekStartDayKey = currentWeekStartDayKey
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Reset Log

@Model
final class LunixiaPointsResetLog {
    var id: UUID = UUID()
    var userId: String = ""
    var weekStartDayKey: String = ""
    var resetAt: Date = Date()
    var pointsBeforeReset: Int = 0
    var levelBeforeReset: Int = 0
    var createdAt: Date = Date()

    init(
        userId: String = "",
        weekStartDayKey: String = "",
        resetAt: Date = Date(),
        pointsBeforeReset: Int = 0,
        levelBeforeReset: Int = 0
    ) {
        self.id = UUID()
        self.userId = userId
        self.weekStartDayKey = weekStartDayKey
        self.resetAt = resetAt
        self.pointsBeforeReset = max(0, pointsBeforeReset)
        self.levelBeforeReset = max(0, levelBeforeReset)
        self.createdAt = resetAt
    }
}
