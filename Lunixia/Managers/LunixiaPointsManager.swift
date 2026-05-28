//
//  LunixiaPointsManager.swift
//  Lunixia
//

import Foundation
import SwiftData

enum LunixiaPointsError: Error {
    case noActiveUser
    case insufficientPoints
}

enum LunixiaPointsManager {

    // MARK: - Point Values

    static let journalEntryPoints    = 20
    static let moodLogPoints         = 15
    static let vitalsLogPoints       = 10
    static let exerciseLogPoints     = 10
    static let medicationTakenPoints = 8
    static let waterLogPoints        = 10
    static let waterGoalPoints        = 20
    static let stepGoalPoints         = 20
    static let dailyIntentionPoints   = 10

    // MARK: - Leveling (100 pts per level)

    static let pointsPerLevel = 100

    static func level(for points: Int) -> Int { max(0, points) / pointsPerLevel }
    static func progressInCurrentLevel(for points: Int) -> Int { max(0, points) % pointsPerLevel }
    static func pointsNeededToNextLevel(for points: Int) -> Int {
        pointsPerLevel - progressInCurrentLevel(for: points)
    }

    // MARK: - Date Helpers

    static func dayKey(from date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static func weekStartDayKey(from date: Date = Date()) -> String {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        let weekday = cal.component(.weekday, from: startOfDay)
        let daysFromMonday = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
        return dayKey(from: monday)
    }

    // MARK: - User Resolution

    static func resolveUserId(in modelContext: ModelContext) throws -> String {
        let descriptor = FetchDescriptor<AuthUser>(sortBy: [SortDescriptor(\.createdAt)])
        let users = try modelContext.fetch(descriptor)
        guard let user = users.first else { throw LunixiaPointsError.noActiveUser }
        if let id = user.serverId,    !id.isEmpty { return id }
        if let id = user.appleUserId, !id.isEmpty { return id }
        if let id = user.googleUserId, !id.isEmpty { return id }
        if let id = user.email,       !id.isEmpty { return id.lowercased() }
        throw LunixiaPointsError.noActiveUser
    }

    // MARK: - Profile

    @discardableResult
    static func fetchOrCreateProfile(in modelContext: ModelContext, userId: String) throws -> LunixiaPointsProfile {
        let descriptor = FetchDescriptor<LunixiaPointsProfile>(predicate: #Predicate { $0.userId == userId })
        if let existing = try modelContext.fetch(descriptor).first { return existing }
        let profile = LunixiaPointsProfile(userId: userId, currentWeekStartDayKey: weekStartDayKey())
        modelContext.insert(profile)
        try modelContext.save()
        return profile
    }

    static func fetchProfile(in modelContext: ModelContext, userId: String) throws -> LunixiaPointsProfile? {
        let descriptor = FetchDescriptor<LunixiaPointsProfile>(predicate: #Predicate { $0.userId == userId })
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Duplicate guard

    static func hasEntry(in modelContext: ModelContext, userId: String, sourceKey: String) throws -> Bool {
        let descriptor = FetchDescriptor<LunixiaPointEntry>(
            predicate: #Predicate { $0.userId == userId && $0.sourceKey == sourceKey }
        )
        return try !modelContext.fetch(descriptor).isEmpty
    }

    // MARK: - Points earned today

    static func pointsEarnedToday(in modelContext: ModelContext, userId: String) throws -> Int {
        let today = dayKey()
        let descriptor = FetchDescriptor<LunixiaPointEntry>(
            predicate: #Predicate { $0.userId == userId && $0.dayKey == today }
        )
        return try modelContext.fetch(descriptor).reduce(0) { $0 + max(0, $1.points) }
    }

    // MARK: - Award

    @discardableResult
    static func awardPoints(
        in modelContext: ModelContext,
        sourceType: LunixiaPointSourceType,
        sourceId: String? = nil,
        sourceKey: String,
        points: Int,
        title: String,
        earnedAt: Date = Date()
    ) throws -> Bool {
        let safe = max(0, points)
        guard safe > 0 else { return false }
        let userId = try resolveUserId(in: modelContext)
        if try hasEntry(in: modelContext, userId: userId, sourceKey: sourceKey) { return false }
        let profile = try fetchOrCreateProfile(in: modelContext, userId: userId)
        let entry = LunixiaPointEntry(
            userId: userId,
            sourceType: sourceType,
            sourceId: sourceId,
            sourceKey: sourceKey,
            dayKey: dayKey(from: earnedAt),
            points: safe,
            title: title,
            createdAt: earnedAt
        )
        modelContext.insert(entry)
        profile.currentPoints  += safe
        profile.lifetimePoints += safe
        profile.level = level(for: profile.currentPoints)
        profile.lastEarnedAt = earnedAt
        profile.updatedAt = Date()
        try modelContext.save()
        return true
    }

    // MARK: - Delete entry & adjust

    @discardableResult
    static func deleteEntryAndAdjust(in modelContext: ModelContext, entry: LunixiaPointEntry) throws -> Bool {
        let userId = try resolveUserId(in: modelContext)
        let profile = try fetchOrCreateProfile(in: modelContext, userId: userId)
        let safe = max(0, entry.points)
        let currentWeekKey = weekStartDayKey()
        let entryWeekKey   = weekStartDayKey(from: entry.createdAt)
        profile.lifetimePoints = max(0, profile.lifetimePoints - safe)
        if entryWeekKey == currentWeekKey {
            profile.currentPoints = max(0, profile.currentPoints - safe)
        }
        profile.level = level(for: profile.currentPoints)
        profile.updatedAt = Date()
        modelContext.delete(entry)
        try modelContext.save()
        return true
    }

    // MARK: - Manual snapshot

    @discardableResult
    static func createSnapshot(in modelContext: ModelContext, now: Date = Date()) throws -> Bool {
        let userId = try resolveUserId(in: modelContext)
        let profile = try fetchOrCreateProfile(in: modelContext, userId: userId)
        let key = "manual-\(profile.currentWeekStartDayKey)-\(Int(now.timeIntervalSince1970))"
        let snap = LunixiaPointsResetLog(
            userId: userId,
            weekStartDayKey: key,
            resetAt: now,
            pointsBeforeReset: profile.currentPoints,
            levelBeforeReset: profile.level
        )
        modelContext.insert(snap)
        try modelContext.save()
        return true
    }

    // MARK: - Weekly reset timer (call from LunixiaApp)

    private static var resetTimer: Timer?

    @MainActor
    static func scheduleWeeklyReset(modelContainer: ModelContainer) {
        resetTimer?.invalidate()

        performDueWeeklyResetIfNeeded(modelContainer: modelContainer)

        let now = Date()
        let nextResetDate = nextMondayMidnight(after: now)
        let interval = max(1, nextResetDate.timeIntervalSince(now))

        resetTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            Task { @MainActor in
                performDueWeeklyResetIfNeeded(modelContainer: modelContainer, now: Date())
                scheduleWeeklyReset(modelContainer: modelContainer)
            }
        }

        if let resetTimer {
            RunLoop.main.add(resetTimer, forMode: .common)
        }
    }

    @MainActor
    static func performDueWeeklyResetIfNeeded(modelContainer: ModelContainer, now: Date = Date()) {
        let ctx = modelContainer.mainContext

        guard let userId = try? resolveUserId(in: ctx),
              let profile = try? fetchProfile(in: ctx, userId: userId) else {
            return
        }

        let currentWeekKey = weekStartDayKey(from: now)

        guard profile.currentWeekStartDayKey != currentWeekKey else {
            return
        }

        let alreadyLogged = hasResetLog(
            in: ctx,
            userId: userId,
            weekStartDayKey: profile.currentWeekStartDayKey
        )

        if !alreadyLogged {
            let snap = LunixiaPointsResetLog(
                userId: userId,
                weekStartDayKey: profile.currentWeekStartDayKey,
                resetAt: now,
                pointsBeforeReset: profile.currentPoints,
                levelBeforeReset: profile.level
            )
            ctx.insert(snap)
        }

        profile.currentPoints = 0
        profile.level = 0
        profile.lastWeeklyResetAt = now
        profile.currentWeekStartDayKey = currentWeekKey
        profile.updatedAt = now

        try? ctx.save()
    }

    @discardableResult
    @MainActor
    static func captureHistoryAndResetNow(in modelContext: ModelContext, now: Date = Date()) throws -> Bool {
        let userId = try resolveUserId(in: modelContext)
        let profile = try fetchOrCreateProfile(in: modelContext, userId: userId)

        let resetLog = LunixiaPointsResetLog(
            userId: userId,
            weekStartDayKey: "manual-reset-\(profile.currentWeekStartDayKey)-\(Int(now.timeIntervalSince1970))",
            resetAt: now,
            pointsBeforeReset: profile.currentPoints,
            levelBeforeReset: profile.level
        )

        modelContext.insert(resetLog)

        profile.currentPoints = 0
        profile.level = 0
        profile.lastWeeklyResetAt = now
        profile.currentWeekStartDayKey = weekStartDayKey(from: now)
        profile.updatedAt = now

        try modelContext.save()
        return true
    }

    private static func nextMondayMidnight(after date: Date) -> Date {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: date)
        let weekday = cal.component(.weekday, from: startOfToday)
        let daysUntilMonday = (9 - weekday) % 7
        let candidateMonday = cal.date(byAdding: .day, value: daysUntilMonday, to: startOfToday) ?? startOfToday

        if candidateMonday > date {
            return candidateMonday
        }

        return cal.date(byAdding: .day, value: 7, to: candidateMonday) ?? candidateMonday
    }

    private static func hasResetLog(
        in modelContext: ModelContext,
        userId: String,
        weekStartDayKey: String
    ) -> Bool {
        let descriptor = FetchDescriptor<LunixiaPointsResetLog>(
            predicate: #Predicate {
                $0.userId == userId && $0.weekStartDayKey == weekStartDayKey
            }
        )

        return ((try? modelContext.fetch(descriptor)) ?? []).isEmpty == false
    }

    // MARK: - Convenience award methods

    @discardableResult
    static func awardJournalEntry(in ctx: ModelContext, id: String, title: String = "Journal Entry", at date: Date = Date()) throws -> Bool {
        try awardPoints(in: ctx, sourceType: .journalEntry, sourceId: id, sourceKey: "journalEntry:\(id)", points: journalEntryPoints, title: title, earnedAt: date)
    }

    @discardableResult
    static func awardMoodLog(in ctx: ModelContext, id: String, at date: Date = Date()) throws -> Bool {
        try awardPoints(in: ctx, sourceType: .moodLog, sourceId: id, sourceKey: "moodLog:\(id)", points: moodLogPoints, title: "Mood Log", earnedAt: date)
    }

    @discardableResult
    static func awardVitalsLog(in ctx: ModelContext, id: String, at date: Date = Date()) throws -> Bool {
        try awardPoints(in: ctx, sourceType: .vitalsLog, sourceId: id, sourceKey: "vitalsLog:\(id)", points: vitalsLogPoints, title: "Vitals Logged", earnedAt: date)
    }

    @discardableResult
    static func awardExerciseLog(in ctx: ModelContext, id: String, at date: Date = Date()) throws -> Bool {
        try awardPoints(in: ctx, sourceType: .exerciseLog, sourceId: id, sourceKey: "exerciseLog:\(id)", points: exerciseLogPoints, title: "Exercise Logged", earnedAt: date)
    }

    @discardableResult
    static func awardMedicationTaken(in ctx: ModelContext, medId: String, dayKey dk: String) throws -> Bool {
        try awardPoints(in: ctx, sourceType: .medicationTaken, sourceId: medId, sourceKey: "medicationTaken:\(medId):\(dk)", points: medicationTakenPoints, title: "Medication Taken")
    }

    @discardableResult
    static func awardWaterLog(in ctx: ModelContext, entryId: String, at date: Date = Date()) throws -> Bool {
        try awardPoints(in: ctx, sourceType: .waterLog, sourceId: entryId, sourceKey: "waterLog:\(entryId)", points: waterLogPoints, title: "Water Logged", earnedAt: date)
    }

    @discardableResult
    static func awardWaterGoal(in ctx: ModelContext, dayKey dk: String) throws -> Bool {
        try awardPoints(in: ctx, sourceType: .waterGoal, sourceKey: "waterGoal:\(dk)", points: waterGoalPoints, title: "Water Goal Reached!")
    }

    @discardableResult
    static func awardStepGoal(in ctx: ModelContext, dayKey dk: String) throws -> Bool {
        try awardPoints(in: ctx, sourceType: .stepGoal, sourceKey: "stepGoal:\(dk)", points: stepGoalPoints, title: "Step Goal Reached!")
    }

    @discardableResult
    static func awardDailyIntention(in ctx: ModelContext, id: String, at date: Date = Date()) throws -> Bool {
        try awardPoints(
            in: ctx,
            sourceType: .dailyIntention,
            sourceId: id,
            sourceKey: "dailyIntention:\(id)",
            points: dailyIntentionPoints,
            title: "Daily Intention",
            earnedAt: date
        )
    }
}
