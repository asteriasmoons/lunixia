//
//  JournalEntryWriter.swift
//  Lystaria
//
//  Created by Asteria Moon on 3/13/26.
//

import SwiftData
import Foundation

enum JournalEntryWriter {

    static func saveEntry(
        title: String,
        content: String,
        tags: [String],
        book: JournalBook,
        modelContext: ModelContext
    ) throws {

        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let attributed = NSAttributedString(string: content)

        let entry = JournalEntry(
            title: cleanedTitle,
            bodyAttributedText: attributed,
            tags: cleanedTags,
            book: book
        )

        entry.updatedAt = Date()

        modelContext.insert(entry)

        try modelContext.save()
    }
}
