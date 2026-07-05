//
//  MoodStatsReportScene.swift
//  LunixiaReport
//

@preconcurrency import DeviceActivity
import ExtensionKit
import Foundation
import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let lunixiaMoodStats = DeviceActivityReport.Context("Lunixia Mood Stats")
}

struct MoodStatsReportScene: DeviceActivityReportScene {

    let context: DeviceActivityReport.Context = .lunixiaMoodStats

    let content: (MoodStatsReportModel) -> MoodStatsReportView

    init() {
        self.content = { model in
            MoodStatsReportView(model: model)
        }
    }

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> MoodStatsReportModel {
        print("[LunixiaReport] makeConfiguration called")

        var totalScreenTime: TimeInterval = 0
        var socialAppTime: TimeInterval = 0
        var nighttimePhoneTime: TimeInterval = 0
        var totalPickups: Int = 0
        var totalNotifications: Int = 0

        let activityData = await data.collect()
        let calendar = Calendar.current

        for deviceData in activityData {
            let segments = await deviceData.activitySegments.collect()

            for segment in segments {
                totalScreenTime += segment.totalActivityDuration
                if Self.isNighttime(segment.dateInterval, calendar: calendar) {
                    nighttimePhoneTime += segment.totalActivityDuration
                }
                totalPickups += segment.totalPickupsWithoutApplicationActivity

                let categories = await segment.categories.collect()

                for category in categories {
                    if Self.isSocialCategory(category.category.localizedDisplayName) {
                        socialAppTime += category.totalActivityDuration
                    }

                    let applications = await category.applications.collect()

                    for application in applications {
                        totalPickups += application.numberOfPickups
                        totalNotifications += application.numberOfNotifications
                    }
                }
            }
        }

        let model = MoodStatsReportModel(
            date: Calendar.current.startOfDay(for: Date()),
            totalScreenTimeMinutes: totalScreenTime / 60,
            socialAppMinutes: socialAppTime / 60,
            nighttimePhoneMinutes: nighttimePhoneTime / 60,
            pickupCount: totalPickups,
            notificationCount: totalNotifications
        )

        MoodStatsReportPersistence.save(model)

        return model
    }

    private static func isNighttime(
        _ interval: DateInterval,
        calendar: Calendar
    ) -> Bool {
        let hour = calendar.component(.hour, from: interval.start)
        return hour >= 21 || hour < 6
    }

    private static func isSocialCategory(_ displayName: String?) -> Bool {
        guard let displayName else { return false }
        let normalized = displayName.lowercased()
        return normalized.contains("social")
    }
}

extension AsyncSequence where Failure == Never {
    func collect() async -> [Element] {
        var elements: [Element] = []

        for await element in self {
            elements.append(element)
        }

        return elements
    }
}

private enum MoodStatsReportPersistence {
    private static let appGroupIdentifier = "group.com.asteriasmoons.Lunixia"
    private static let latestSnapshotKey = "lunixia.moodStats.latestSnapshot"

    static func save(_ model: MoodStatsReportModel) {
        print("[LunixiaReport] save — screen=\(model.totalScreenTimeMinutes) pickups=\(model.pickupCount) notifications=\(model.notificationCount)")
        let snapshot = SharedMoodPhoneStatsSnapshot(
            date: model.date,
            screenTimeMinutes: model.totalScreenTimeMinutes,
            socialAppMinutes: model.socialAppMinutes,
            nighttimePhoneMinutes: model.nighttimePhoneMinutes,
            pickupCount: model.pickupCount,
            notificationCount: model.notificationCount
        )

        guard let data = try? JSONEncoder().encode(snapshot) else {
            print("[LunixiaReport] save — ENCODE FAILED")
            return
        }

        // Write to UserDefaults
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        print("[LunixiaReport] save — App Group defaults: \(defaults == nil ? "NIL" : "OK")")
        defaults?.set(data, forKey: latestSnapshotKey)
        let didSync = defaults?.synchronize() ?? false
        print("[LunixiaReport] save — synchronize result: \(didSync)")

        // ALSO write to a plain file so the main app can verify the write happened
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let fileURL = containerURL.appendingPathComponent("moodstats_debug.txt")
            let debugString = "screen=\(model.totalScreenTimeMinutes) pickups=\(model.pickupCount) date=\(model.date) written=\(Date())"
            try? debugString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("[LunixiaReport] save — wrote debug file to \(fileURL.path)")
        } else {
            print("[LunixiaReport] save — containerURL is NIL")
        }
    }
}

private struct SharedMoodPhoneStatsSnapshot: Codable {
    let date: Date
    let screenTimeMinutes: Double
    let socialAppMinutes: Double
    let nighttimePhoneMinutes: Double
    let pickupCount: Int
    let notificationCount: Int
}
