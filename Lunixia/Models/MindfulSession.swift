//
//  MindfulSession.swift
//  Lunixia
//

import Foundation
import SwiftData

/// Persists mindful minutes earned from journaling sessions.
/// Synced to iCloud automatically via SwiftData/CloudKit.
@Model
final class MindfulSession {
    /// Links back to the journal entry that generated this session.
    var entryPersistentID: String = ""

    /// The journal book this session belongs to.
    var bookPersistentID: String = ""

    /// Number of mindful minutes earned.
    var minutes: Int = 0

    /// Tags attached to the journal entry at the time of the session.
    var tagsStorage: String = "[]"

    /// AI-generated themes from the analysis (if available).
    var themesStorage: String = "[]"

    /// When the journaling session occurred.
    var date: Date = Date()

    /// Chicago-timezone date key for aggregation (YYYY-MM-DD).
    var dateKey: String = ""

    // MARK: - Computed accessors

    var tags: [String] {
        get {
            guard let data = tagsStorage.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let encoded = String(data: data, encoding: .utf8) {
                tagsStorage = encoded
            } else {
                tagsStorage = "[]"
            }
        }
    }

    var themes: [String] {
        get {
            guard let data = themesStorage.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let encoded = String(data: data, encoding: .utf8) {
                themesStorage = encoded
            } else {
                themesStorage = "[]"
            }
        }
    }

    init(
        entryPersistentID: String = "",
        bookPersistentID: String = "",
        minutes: Int = 0,
        tags: [String] = [],
        themes: [String] = [],
        date: Date = Date(),
        dateKey: String = ""
    ) {
        self.entryPersistentID = entryPersistentID
        self.bookPersistentID = bookPersistentID
        self.minutes = minutes
        self.date = date
        self.dateKey = dateKey.isEmpty ? MindfulSession.chicagoDateKey(from: date) : dateKey
        self.tagsStorage = "[]"
        self.themesStorage = "[]"
        self.tags = tags
        self.themes = themes
    }

    /// Generate a Chicago-timezone date key matching the backend format.
    static func chicagoDateKey(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/Chicago")
        return formatter.string(from: date)
    }
}
