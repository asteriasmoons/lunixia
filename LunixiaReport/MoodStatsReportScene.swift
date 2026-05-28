//
//  MoodStatsReportScene.swift
//  LunixiaReport
//

@preconcurrency import DeviceActivity
import ExtensionKit
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

        var totalScreenTime: TimeInterval = 0
        var totalPickups: Int = 0
        var totalNotifications: Int = 0

        let activityData = await data.collect()

        for deviceData in activityData {
            let segments = await deviceData.activitySegments.collect()

            for segment in segments {
                totalScreenTime += segment.totalActivityDuration
                totalPickups += segment.totalPickupsWithoutApplicationActivity

                let categories = await segment.categories.collect()

                for category in categories {
                    let applications = await category.applications.collect()

                    for application in applications {
                        totalPickups += application.numberOfPickups
                        totalNotifications += application.numberOfNotifications
                    }
                }
            }
        }

        return MoodStatsReportModel(
            totalScreenTimeMinutes: totalScreenTime / 60,
            pickupCount: totalPickups,
            notificationCount: totalNotifications
        )
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
