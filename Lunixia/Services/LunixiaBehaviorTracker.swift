//
//  LunixiaBehaviorTracker.swift
//  Lunixia
//

import DeviceActivity
import FamilyControls
import Foundation
import Combine

/// Manages the FamilyActivitySelection and the 12 two-hour monitoring
/// schedules used to estimate screen time via threshold counting.
@MainActor
final class LunixiaBehaviorTracker: ObservableObject {

    static let shared = LunixiaBehaviorTracker()

    // MARK: - Keys

    static let appGroupID             = "group.com.asteriasmoons.Lunixia"
    static let selectionKey           = "lunixia.behaviorTracker.selection"
    static let screenTimeTodayKey     = "lunixia.behaviorTracker.screenTimeMinutes"
    static let screenTimeDateKey      = "lunixia.behaviorTracker.screenTimeDate"

    // MARK: - Published

    @Published var activitySelection = FamilyActivitySelection()
    @Published var hasSelection: Bool = false
    @Published var estimatedScreenTimeMinutes: Double = 0

    private let center = DeviceActivityCenter()
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()

    private init() {
        loadSavedSelection()
        loadTodayScreenTime()
    }

    // MARK: - Selection persistence (App Group so monitor extension can read tokens)

    func saveSelection(_ selection: FamilyActivitySelection) {
        activitySelection = selection
        hasSelection = !selection.applicationTokens.isEmpty ||
                       !selection.categoryTokens.isEmpty ||
                       !selection.webDomainTokens.isEmpty
        guard let data = try? encoder.encode(selection),
              let defaults = UserDefaults(suiteName: Self.appGroupID) else { return }
        defaults.set(data, forKey: Self.selectionKey)
        defaults.synchronize()
        startMonitoring(selection: selection)
    }

    private func loadSavedSelection() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID),
              let data = defaults.data(forKey: Self.selectionKey),
              let selection = try? decoder.decode(FamilyActivitySelection.self, from: data) else { return }
        activitySelection = selection
        hasSelection = !selection.applicationTokens.isEmpty ||
                       !selection.categoryTokens.isEmpty ||
                       !selection.webDomainTokens.isEmpty
    }

    // MARK: - Screen time read (written by LunixiaMonitor)

    func loadTodayScreenTime() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else { return }
        defaults.synchronize()
        let storedDate = defaults.object(forKey: Self.screenTimeDateKey) as? Date ?? .distantPast
        if Calendar.current.isDateInToday(storedDate) {
            estimatedScreenTimeMinutes = defaults.double(forKey: Self.screenTimeTodayKey)
        } else {
            estimatedScreenTimeMinutes = 0
        }
    }

    // MARK: - Monitoring schedules

    /// Starts 12 two-hour schedules covering 00:00–23:59, each with
    /// DeviceActivityEvent thresholds every 5 minutes (24 events per schedule).
    /// When the user hits a 5-min threshold, LunixiaMonitor increments
    /// the screen time counter by 5 in the App Group.
    func startMonitoring(selection: FamilyActivitySelection) {
        guard !selection.applicationTokens.isEmpty ||
              !selection.categoryTokens.isEmpty else { return }

        // Events: thresholds at 5, 10, 15 ... 115 minutes
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for minute in stride(from: 5, through: 115, by: 5) {
            let name = DeviceActivityEvent.Name("lunixia.behavior.threshold.\(minute)")
            events[name] = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens,
                threshold: DateComponents(minute: minute)
            )
        }

        // 12 two-hour blocks: 0-1, 2-3, 4-5 ... 22-23
        for blockIndex in 0..<12 {
            let startHour = blockIndex * 2
            let endHour   = startHour + 1

            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: startHour, minute: 0, second: 0),
                intervalEnd:   DateComponents(hour: endHour,   minute: 59, second: 59),
                repeats: true
            )

            let activityName = DeviceActivityName("lunixia.behavior.block.\(blockIndex)")
            do {
                try center.startMonitoring(activityName, during: schedule, events: events)
            } catch {
                // Already monitoring this block is fine
            }
        }
    }

    /// Call on app foreground to restart monitoring if a selection exists
    func restartMonitoringIfNeeded() {
        guard hasSelection else { return }
        startMonitoring(selection: activitySelection)
    }
}
