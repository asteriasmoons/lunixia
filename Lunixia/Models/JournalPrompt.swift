//
//  JournalPrompt.swift
//  Lunixia
//

import Foundation
import SwiftData

@Model
final class JournalPrompt {
    var deletedAt: Date?

    // MARK: - Relationship
    var book: JournalBook?

    // MARK: - Fields
    var text: String = ""
    var isCompleted: Bool = false

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        text: String,
        isCompleted: Bool = false,
        book: JournalBook? = nil,
        deletedAt: Date? = nil
    ) {
        self.text = text
        self.isCompleted = isCompleted
        self.book = book
        self.deletedAt = deletedAt
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
