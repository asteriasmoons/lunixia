//
// JournalBook.swift
// Lunixia
//

import Foundation
import SwiftData

@Model
final class JournalBook {
    var deletedAt: Date?

    // MARK: - Fields
    var uuid: UUID = UUID()
    var title: String = ""
    var coverHex: String = "#6A5CFF"
    var pinOrder: Int = 0

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \JournalEntry.book)
    var entries: [JournalEntry]?

    @Relationship(deleteRule: .cascade, inverse: \JournalPrompt.book)
    var prompts: [JournalPrompt]?

    init(
        title: String,
        coverHex: String = "#6A5CFF",
        deletedAt: Date? = nil
    ) {
        self.title = title
        self.coverHex = coverHex
        self.pinOrder = 0
        self.deletedAt = deletedAt
        self.createdAt = Date()
        self.updatedAt = Date()
        self.entries = nil
        self.prompts = nil
    }
}
