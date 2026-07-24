//
//  Note.swift
//  Lunixia
//

import Foundation
import SwiftData

struct NoteChecklistItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

@Model
final class Note {
    static let minimumFontSize: Double = 12
    static let maximumFontSize: Double = 28

    var id: UUID = UUID()

    // Main content
    var content: String = ""
    var colorHex: String = "#6B4CDE"
    var checklistItemsJSON: String = ""
    var fontID: String = "system"
    var fontSize: Double = 15

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
        checklistItemsJSON: String = "",
        fontID: String = "system",
        fontSize: Double = 15,
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
        self.checklistItemsJSON = checklistItemsJSON
        self.fontID = fontID
        self.fontSize = fontSize
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

    var resolvedFontSize: Double {
        min(Self.maximumFontSize, max(Self.minimumFontSize, fontSize))
    }

    // Prevent saving empty notes if you want
    var isEmpty: Bool {
        trimmedContent.isEmpty
    }

    // Used for sticky note preview cards
    var previewText: String {
        let textPreview = trimmedContent.replacingOccurrences(of: "\n", with: " ")
        let checklistPreview = checklistItems
            .map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if textPreview.isEmpty { return checklistPreview }
        if checklistPreview.isEmpty { return textPreview }
        return [textPreview, checklistPreview].joined(separator: " ")
    }

    /// Both labels as an array, omitting empty entries.
    var activeLabels: [String] {
        [label, label2]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var checklistItems: [NoteChecklistItem] {
        get {
            guard !checklistItemsJSON.isEmpty,
                  let data = checklistItemsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([NoteChecklistItem].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let encoded = String(data: data, encoding: .utf8)
            else {
                checklistItemsJSON = ""
                return
            }
            checklistItemsJSON = encoded
        }
    }
}
