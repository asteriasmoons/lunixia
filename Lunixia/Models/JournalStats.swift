//
// JournalStats.swift
// Lunixia
//

import Foundation
import SwiftData

/// Singleton-style model that persists journal streak high-water marks.
/// There should only ever be one instance — query with `stats.first`.
/// CloudKit syncs this automatically alongside all other SwiftData models.
@Model
final class JournalStats {
    var bestStreakEver: Int = 0
    var updatedAt: Date = Date()

    init() {}
}
