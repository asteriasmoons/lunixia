//
//  DailyIntentionWriter.swift
//  Lystaria
//

import Foundation
import SwiftData

@MainActor
enum DailyIntentionWriter {
    static func dayKey(for date: Date = Date()) -> String {
        let cal = Calendar.autoupdatingCurrent
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let normalized = cal.date(from: comps) ?? date

        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: normalized)
    }

    static func normalizedDay(for date: Date = Date()) -> Date {
        let cal = Calendar.autoupdatingCurrent
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return cal.date(from: comps) ?? date
    }

    static func todayKey() -> String {
        dayKey(for: Date())
    }

    static func todayDate() -> Date {
        normalizedDay(for: Date())
    }

    static func fetchRecord(
        for key: String,
        modelContext: ModelContext
    ) throws -> DailyIntention? {
        let descriptor = FetchDescriptor<DailyIntention>(
            predicate: #Predicate<DailyIntention> { $0.dateKey == key }
        )

        let matches = try modelContext.fetch(descriptor)
        return matches.first
    }

    static func fetchOrCreateTodayRecord(
        modelContext: ModelContext
    ) throws -> DailyIntention {
        let key = todayKey()
        let date = todayDate()

        let descriptor = FetchDescriptor<DailyIntention>(
            predicate: #Predicate<DailyIntention> { $0.dateKey == key }
        )

        let matches = try modelContext.fetch(descriptor)

        if let existing = matches.first {
            if matches.count > 1 {
                for dupe in matches.dropFirst() {
                    modelContext.delete(dupe)
                }
                try modelContext.save()
            }
            return existing
        } else {
            let record = DailyIntention(date: date, text: "")
            modelContext.insert(record)
            try modelContext.save()
            return record
        }
    }

    static func setTodayIntention(
        _ text: String,
        modelContext: ModelContext
    ) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let record = try fetchOrCreateTodayRecord(modelContext: modelContext)
        record.text = trimmed
        record.updatedAt = Date()

        try modelContext.save()
        _ = try? LunixiaPointsManager.awardDailyIntention(
            in: modelContext,
            id: record.dateKey,
            at: record.updatedAt
        )
    }

    static func clearTodayIntention(
        modelContext: ModelContext
    ) throws {
        let record = try fetchOrCreateTodayRecord(modelContext: modelContext)
        record.text = ""
        record.updatedAt = Date()

        try modelContext.save()
    }
}
