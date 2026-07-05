//
//  DeviceActivityMonitorExtension.swift
//  LunixiaMonitor
//

import DeviceActivity
import Foundation

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private static let appGroupID         = "group.com.asteriasmoons.Lunixia"
    private static let screenTimeTodayKey = "lunixia.behaviorTracker.screenTimeMinutes"
    private static let screenTimeDateKey  = "lunixia.behaviorTracker.screenTimeDate"

    // MARK: - Threshold hit — add 5 minutes to today's total

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        // Only handle our behavior tracking events
        guard event.rawValue.hasPrefix("lunixia.behavior.threshold.") else { return }

        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else { return }
        defaults.synchronize()

        let storedDate = defaults.object(forKey: Self.screenTimeDateKey) as? Date ?? .distantPast
        let today = Calendar.current.startOfDay(for: Date())

        var currentMinutes: Double
        if Calendar.current.isDate(storedDate, inSameDayAs: today) {
            currentMinutes = defaults.double(forKey: Self.screenTimeTodayKey)
        } else {
            // New day — reset
            currentMinutes = 0
            defaults.set(today, forKey: Self.screenTimeDateKey)
        }

        currentMinutes += 5
        defaults.set(currentMinutes, forKey: Self.screenTimeTodayKey)
        defaults.synchronize()
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }
}
