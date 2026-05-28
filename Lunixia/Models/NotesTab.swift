//
//  NotesTab.swift
//  Lunixia
//

import Foundation
import SwiftData

@Model
final class NotesTab {
    var id: UUID = UUID()
    var name: String = ""
    var isRootTab: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String = "",
        isRootTab: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isRootTab = isRootTab
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func touch() {
        updatedAt = Date()
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmpty: Bool {
        trimmedName.isEmpty
    }

    var isDefaultTab: Bool {
        isRootTab
    }
}
