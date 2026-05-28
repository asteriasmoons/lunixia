//
//  JournalEditorRoutePage.swift
//  Lunixia
//

import SwiftUI
import SwiftData

struct JournalEditorRoutePage: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let book: JournalBook
    let existingEntry: JournalEntry?

    @State private var preparedEntry: JournalEntry?
    @State private var hasPrepared = false

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            Group {
                if let preparedEntry {
                    JournalBlockEditorPage(
                        book: book,
                        existingEntry: preparedEntry,
                        isNewEntryDraft: existingEntry == nil
                    )
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            guard !hasPrepared else { return }
            hasPrepared = true

            print("[RoutePage] preparing editor route")

            prepareEntry()
        }
    }

    private func prepareEntry() {
        if let existingEntry {
            print("[RoutePage] using existing entry")

            preparedEntry = existingEntry
            return
        }

        print("[RoutePage] creating new draft entry")

        let entry = JournalEntry()

        entry.book = book
        entry.createdAt = Date()
        entry.updatedAt = Date()

        entry.ensureStarterBlock()
        entry.normalizeBlockSortOrders()

        modelContext.insert(entry)

        do {
            try modelContext.save()

            print("[RoutePage] successfully inserted and saved draft entry")

            preparedEntry = entry
        } catch {
            print("[RoutePage] failed saving draft entry: \(error)")
        }
    }
}
