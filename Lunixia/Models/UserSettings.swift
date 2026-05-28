//
// UserSettings.swift
// Lunixia
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    // Optional server sync id later (MongoDB settings doc id)
    var serverId: String?

    // If true: always use the device timezone (TimeZone.current.identifier)
    // If false: use timezoneIdentifier below.
    var useSystemTimezone: Bool = true

    // IANA timezone id like "America/Chicago"
    // Only used when useSystemTimezone == false
    var timezoneIdentifier: String = TimeZone.current.identifier

    // Reading tab default status filter.
    // Stores BookStatus.rawValue, or "" for "All" (nil filter).
    var readingDefaultStatusFilter: String = ""

    // Apple Calendar sync — stores the EKCalendar.calendarIdentifier the user
    // chose to sync with. Empty string means no calendar selected.
    var calendarSyncSelectedIdentifier: String = ""

    // Sleep goal in hours.
    var sleepGoalHours: Double = 8

    // Notes tab default view.
    // Stores the tab name the user set as default. Empty string means use root tab.
    var notesDefaultTab: String = ""

    // Whether the user has completed the welcome flow.
    var hasSeenWelcome: Bool = false

    // Whether the app has already requested HealthKit authorization.
    // This does NOT mean authorization was granted — only that the prompt was shown.
    var didRequestHealthKitAuthorization: Bool = false

    // Premium bypass kill switch.
    // If true: all premium gates and feature limits are disabled for this user's synced settings record.
    var premiumBypassEnabled: Bool = true

    // Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var needsSync: Bool = false

    init(
        serverId: String? = nil,
        useSystemTimezone: Bool = true,
        timezoneIdentifier: String = TimeZone.current.identifier,
        readingDefaultStatusFilter: String = "",
        hasSeenWelcome: Bool = false,
        didRequestHealthKitAuthorization: Bool = false,
        premiumBypassEnabled: Bool = true,
        needsSync: Bool = false
    ) {
        self.serverId = serverId
        self.useSystemTimezone = useSystemTimezone
        self.timezoneIdentifier = timezoneIdentifier
        self.readingDefaultStatusFilter = readingDefaultStatusFilter
        self.hasSeenWelcome = hasSeenWelcome
        self.didRequestHealthKitAuthorization = didRequestHealthKitAuthorization
        self.premiumBypassEnabled = premiumBypassEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
        self.needsSync = needsSync
    }

    // Computed convenience
    var effectiveTimezoneIdentifier: String {
        useSystemTimezone ? TimeZone.current.identifier : timezoneIdentifier
    }
}
