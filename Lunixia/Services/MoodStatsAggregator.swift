//
//  MoodStatsAggregator.swift
//  Lunixia
//

import Foundation

struct MoodPhoneUsageTotals {
    var screenTimeMinutes: Double
    var socialAppMinutes: Double
    var nighttimePhoneMinutes: Double
    var pickupCount: Int
    var notificationCount: Int
}

struct MoodStatsMoodInput {
    var date: Date
    var moodTitle: String
    var moodIcon: String
    var moodScore: Double
}

struct SharedMoodPhoneStatsSnapshot: Codable {
    let date: Date
    let screenTimeMinutes: Double
    let socialAppMinutes: Double
    let nighttimePhoneMinutes: Double
    let pickupCount: Int
    let notificationCount: Int
}

enum MoodStatsSharedStore {
    static let appGroupIdentifier = "group.com.asteriasmoons.Lunixia"
    static let latestSnapshotKey = "lunixia.moodStats.latestSnapshot"

    static func latestSnapshot() -> SharedMoodPhoneStatsSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        defaults.synchronize()
        guard let data = defaults.data(forKey: latestSnapshotKey) else { return nil }
        return try? JSONDecoder().decode(SharedMoodPhoneStatsSnapshot.self, from: data)
    }
}

@MainActor
final class MoodStatsAggregator {

    static let shared = MoodStatsAggregator()

    private init() {}

    func buildDailySnapshot(
        for date: Date,
        moodLogs: [MoodStatsMoodInput],
        phoneUsage: MoodPhoneUsageTotals
    ) -> MoodPhoneStatsSnapshot {

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        let dayLogs = moodLogs.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }

        let averageMoodScore = calculateAverageMoodScore(from: dayLogs)
        let mostCommonMood = calculateMostCommonMood(from: dayLogs)

        return MoodPhoneStatsSnapshot(
            date: dayStart,
            screenTimeMinutes: phoneUsage.screenTimeMinutes,
            socialAppMinutes: phoneUsage.socialAppMinutes,
            nighttimePhoneMinutes: phoneUsage.nighttimePhoneMinutes,
            pickupCount: phoneUsage.pickupCount,
            notificationCount: phoneUsage.notificationCount,
            averageMoodScore: averageMoodScore,
            moodCheckInCount: dayLogs.count,
            mostCommonMoodTitle: mostCommonMood.title,
            mostCommonMoodIcon: mostCommonMood.icon,
            source: "deviceActivity",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func updateSnapshot(
        _ snapshot: MoodPhoneStatsSnapshot,
        moodLogs: [MoodStatsMoodInput],
        phoneUsage: MoodPhoneUsageTotals
    ) {
        let calendar = Calendar.current

        let dayLogs = moodLogs.filter {
            calendar.isDate($0.date, inSameDayAs: snapshot.date)
        }

        let averageMoodScore = calculateAverageMoodScore(from: dayLogs)
        let mostCommonMood = calculateMostCommonMood(from: dayLogs)

        snapshot.screenTimeMinutes = phoneUsage.screenTimeMinutes
        snapshot.socialAppMinutes = phoneUsage.socialAppMinutes
        snapshot.nighttimePhoneMinutes = phoneUsage.nighttimePhoneMinutes
        snapshot.pickupCount = phoneUsage.pickupCount
        snapshot.notificationCount = phoneUsage.notificationCount

        snapshot.averageMoodScore = averageMoodScore
        snapshot.moodCheckInCount = dayLogs.count
        snapshot.mostCommonMoodTitle = mostCommonMood.title
        snapshot.mostCommonMoodIcon = mostCommonMood.icon

        snapshot.updatedAt = Date()
    }

    private func calculateAverageMoodScore(
        from logs: [MoodStatsMoodInput]
    ) -> Double {
        guard !logs.isEmpty else { return 0 }

        let total = logs.reduce(0.0) { partialResult, log in
            partialResult + log.moodScore
        }

        return total / Double(logs.count)
    }

    private func calculateMostCommonMood(
        from logs: [MoodStatsMoodInput]
    ) -> (title: String, icon: String) {
        guard !logs.isEmpty else {
            return ("None", "moodIcon")
        }

        var counts: [String: Int] = [:]
        var iconLookup: [String: String] = [:]

        for log in logs {
            counts[log.moodTitle, default: 0] += 1
            iconLookup[log.moodTitle] = log.moodIcon
        }

        guard let mostCommon = counts.max(by: { $0.value < $1.value }) else {
            return ("None", "moodIcon")
        }

        return (
            mostCommon.key,
            iconLookup[mostCommon.key] ?? "moodIcon"
        )
    }
}
