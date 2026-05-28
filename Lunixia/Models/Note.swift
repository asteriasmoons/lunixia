//
//  Note.swift
//  Lunixia
//

import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID = UUID()

    // Main content
    var content: String = ""
    var colorHex: String = "#6B4CDE"

    // Original stored label — kept intact so existing data is not lost
    var label: String = ""
    // Second label stored as a plain string (empty = not set)
    var label2: String = ""

    var tabName: String = "All Notes"

    // Markers
    var isPinned: Bool = false
    var isFavorite: Bool = false

    // Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        content: String = "",
        colorHex: String = "#6B4CDE",
        label: String = "",
        label2: String = "",
        tabName: String = "All Notes",
        isPinned: Bool = false,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.colorHex = colorHex
        self.label = label
        self.label2 = label2
        self.tabName = tabName
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Call this whenever content changes
    func touch() {
        updatedAt = Date()
    }

    // Cleaned content (for safety checks)
    var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Prevent saving empty notes if you want
    var isEmpty: Bool {
        trimmedContent.isEmpty
    }

    // Used for sticky note preview cards
    var previewText: String {
        trimmedContent
            .replacingOccurrences(of: "\n", with: " ")
    }

    /// Both labels as an array, omitting empty entries.
    var activeLabels: [String] {
        [label, label2]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
