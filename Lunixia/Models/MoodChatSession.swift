//
//  MoodChatSession.swift
//  Lunixia
//

import Foundation
import SwiftData

@Model
final class MoodChatSession {
    var lastChatDate: Date?

    init(lastChatDate: Date? = nil) {
        self.lastChatDate = lastChatDate
    }

    /// Returns true if the user is eligible to start a new chat (no chat in the last 12 hours).
    var canStartChat: Bool {
        guard let last = lastChatDate else { return true }
        return Date().timeIntervalSince(last) >= 12 * 3600
    }

    /// Seconds remaining until the next chat is allowed. 0 if already eligible.
    var cooldownSecondsRemaining: TimeInterval {
        guard let last = lastChatDate else { return 0 }
        let elapsed = Date().timeIntervalSince(last)
        let remaining = (12 * 3600) - elapsed
        return max(0, remaining)
    }
}
