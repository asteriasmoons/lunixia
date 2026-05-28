//
//  JournalPromptUsage.swift
//  Lunixia
//

import Foundation
import SwiftData

@Model
final class JournalPromptUsage {

    // MARK: - Properties

    /// Stable signed-in Apple user identifier this usage record belongs to
    var userId: String = ""

    /// Format: "yyyy-MM-dd" (e.g., "2026-03-17")
    var dateKey: String = ""

    /// How many prompts have been used for this date
    var usedCount: Int = 0

    /// Last time this record was updated
    var updatedAt: Date = Date()

    // MARK: - Init

    init(userId: String, dateKey: String, usedCount: Int = 0, updatedAt: Date = Date()) {
        self.userId = userId
        self.dateKey = dateKey
        self.usedCount = usedCount
        self.updatedAt = updatedAt
    }
}
