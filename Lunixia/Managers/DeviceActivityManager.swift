//
//  DeviceActivityManager.swift
//  Lunixia
//

import SwiftUI
import Combine
import FamilyControls
import DeviceActivity

@MainActor
final class DeviceActivityManager: ObservableObject {

    static let shared = DeviceActivityManager()

    @Published var authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    @Published var selectedActivity = FamilyActivitySelection()
    @Published var isRequestingAuthorization = false
    @Published var errorMessage: String?

    private let center = DeviceActivityCenter()

    private init() {}

    // MARK: - Authorization

    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() async {
        isRequestingAuthorization = true
        errorMessage = nil

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refreshAuthorizationStatus()
        } catch {
            errorMessage = error.localizedDescription
            refreshAuthorizationStatus()
        }

        isRequestingAuthorization = false
    }

    // MARK: - Selection

    var hasSelection: Bool {
        !selectedActivity.applicationTokens.isEmpty ||
        !selectedActivity.categoryTokens.isEmpty ||
        !selectedActivity.webDomainTokens.isEmpty
    }

    func updateSelection(_ selection: FamilyActivitySelection) {
        selectedActivity = selection
    }

    func clearSelection() {
        selectedActivity = FamilyActivitySelection()
    }

    // MARK: - Mood Stats Monitoring

    func startMoodStatsMonitoring() {
        guard isAuthorized else {
            errorMessage = "Device Activity permission has not been approved yet."
            return
        }

        stopMoodStatsMonitoring()
        startFullDayMonitoring()
        startNighttimeMonitoring()
    }

    func stopMoodStatsMonitoring() {
        center.stopMonitoring([
            .lunixiaScreenTime,
            .lunixiaSocialUsage,
            .lunixiaNighttimeUsage,
            .lunixiaPickups,
            .lunixiaNotifications
        ])
    }

    private func startFullDayMonitoring() {
        let fullDaySchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(.lunixiaScreenTime, during: fullDaySchedule)
            try center.startMonitoring(.lunixiaSocialUsage, during: fullDaySchedule)
            try center.startMonitoring(.lunixiaPickups, during: fullDaySchedule)
            try center.startMonitoring(.lunixiaNotifications, during: fullDaySchedule)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startNighttimeMonitoring() {
        let nighttimeSchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 21, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(.lunixiaNighttimeUsage, during: nighttimeSchedule)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Device Activity Names

extension DeviceActivityName {
    static let lunixiaScreenTime = Self("lunixia.screen.time")
    static let lunixiaSocialUsage = Self("lunixia.social.usage")
    static let lunixiaNighttimeUsage = Self("lunixia.nighttime.usage")
    static let lunixiaPickups = Self("lunixia.pickups")
    static let lunixiaNotifications = Self("lunixia.notifications")
}

// MARK: - Device Activity Report Contexts

extension DeviceActivityReport.Context {
    static let lunixiaMoodStats = Self("Lunixia Mood Stats")
    static let lunixiaScreenTime = Self("Lunixia Screen Time")
    static let lunixiaSocialUsage = Self("Lunixia Social Usage")
    static let lunixiaNighttimeUsage = Self("Lunixia Nighttime Usage")
    static let lunixiaPickups = Self("Lunixia Pickups")
    static let lunixiaNotifications = Self("Lunixia Notifications")
}
