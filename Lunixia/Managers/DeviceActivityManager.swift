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
    private let hasRequestedKey = "lunixia.deviceActivity.hasRequested"
    private let hasApprovedDeviceActivityKey = "Lunixia.hasApprovedDeviceActivityAccess"

    private init() {}

    // MARK: - Authorization

    var isAuthorized: Bool {
        let statusDescription = String(describing: authorizationStatus).lowercased()
        let reflectedDescription = String(reflecting: authorizationStatus).lowercased()
        let combinedStatus = statusDescription + " " + reflectedDescription

        if combinedStatus.contains("approved") {
            UserDefaults.standard.set(true, forKey: hasApprovedDeviceActivityKey)
            return true
        }

        if combinedStatus.contains("denied") || combinedStatus.contains("revoked") {
            UserDefaults.standard.set(false, forKey: hasApprovedDeviceActivityKey)
            return false
        }

        return UserDefaults.standard.bool(forKey: hasApprovedDeviceActivityKey)
    }

    /// True if we have ever shown the permission prompt, regardless of outcome.
    /// Persisted across launches so we never re-prompt automatically.
    var hasEverRequested: Bool {
        get { UserDefaults.standard.bool(forKey: hasRequestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRequestedKey) }
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus

        print(
            "[DeviceActivity] authorizationStatus:",
            AuthorizationCenter.shared.authorizationStatus,
            "storedApproved:",
            UserDefaults.standard.bool(forKey: hasApprovedDeviceActivityKey),
            "isAuthorized:",
            isAuthorized
        )
    }

    func requestAuthorization() async {
        guard !isAuthorized else { return }
        isRequestingAuthorization = true
        errorMessage = nil
        hasEverRequested = true

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)

            print(
                "[DeviceActivity] status after request:",
                AuthorizationCenter.shared.authorizationStatus
            )

            refreshAuthorizationStatus()

            if isAuthorized {
                UserDefaults.standard.set(true, forKey: hasApprovedDeviceActivityKey)
            }
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

    func startMoodStatsMonitoringIfNeeded() {
        guard isAuthorized else { return }
        startNighttimeMonitoring()
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
            // Already monitoring is not an error worth surfacing
        }
    }
}

// MARK: - Device Activity Names

extension DeviceActivityName {
    static let lunixiaNighttimeUsage = Self("lunixia.nighttime.usage")
    static func behaviorBlock(_ index: Int) -> Self { Self("lunixia.behavior.block.\(index)") }
}

// MARK: - Device Activity Report Contexts

extension DeviceActivityReport.Context {
    static let lunixiaMoodStats = Self("Lunixia Mood Stats")
}
