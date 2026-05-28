//
//  MedicationNotificationManager.swift
//  Lunixia
//

import Foundation
import UserNotifications

final class MedicationNotificationManager {

    static let shared = MedicationNotificationManager()
    private init() {}

    // MARK: - Permission

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // MARK: - Reschedule

    func reschedule(for medication: LunixiaMedication) {
        cancelAll(for: medication)
        guard medication.isActive else { return }
        if medication.notifyDose {
            scheduleDoseNotifications(for: medication)
        }
        if medication.notifyRefill,
           let refillDate = medication.refillDate,
           medication.daysBeforeRefillNotify > 0 {
            scheduleRefillNotification(for: medication, refillDate: refillDate)
        }
    }

    // MARK: - Cancel

    func cancelAll(for medication: LunixiaMedication) {
        var ids: [String] = [refillID(medication)]
        // Up to 10 time slots × 7 weekdays
        for timeIndex in 0..<10 {
            for weekday in 1...7 {
                ids.append(doseID(medication, timeIndex: timeIndex, weekday: weekday))
            }
            ids.append(doseDefaultID(medication, timeIndex: timeIndex))
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Dose Notifications

    /// Schedules one notification per (time, weekday) combination.
    /// For weekdays with a per-day override the body reflects that dose count.
    /// For weekdays using the default the body reflects the default count.
    private func scheduleDoseNotifications(for medication: LunixiaMedication) {
        let times = medication.doseNotifyTimes
        let overrides = medication.doseScheduleOverrides
        let allWeekdays = Set(1...7)
        let overriddenWeekdays = Set(overrides.keys)
        let defaultWeekdays = allWeekdays.subtracting(overriddenWeekdays)

        for (timeIndex, time) in times.enumerated() {
            // Per-weekday overrides
            for (weekday, doses) in overrides {
                let content = doseContent(name: medication.name, doses: doses)
                var comps = DateComponents()
                comps.weekday = weekday
                comps.hour = time.hour
                comps.minute = time.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let request = UNNotificationRequest(
                    identifier: doseID(medication, timeIndex: timeIndex, weekday: weekday),
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }

            // Default weekdays
            guard !defaultWeekdays.isEmpty else { continue }
            let defaultDoses = medication.timesPerDay
            let content = doseContent(name: medication.name, doses: defaultDoses)

            if overriddenWeekdays.isEmpty {
                // No overrides at all — single repeating trigger
                var comps = DateComponents()
                comps.hour = time.hour
                comps.minute = time.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let request = UNNotificationRequest(
                    identifier: doseDefaultID(medication, timeIndex: timeIndex),
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            } else {
                // Schedule per remaining weekday so overridden days aren't hit
                for weekday in defaultWeekdays {
                    var comps = DateComponents()
                    comps.weekday = weekday
                    comps.hour = time.hour
                    comps.minute = time.minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    let request = UNNotificationRequest(
                        identifier: doseID(medication, timeIndex: timeIndex, weekday: weekday),
                        content: content,
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }

    private func doseContent(name: String, doses: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Time to take \(name)"
        content.body = doses > 1 ? "You have \(doses) doses scheduled today." : "Don't forget your dose today."
        content.sound = .default
        return content
    }

    // MARK: - Refill Notification

    private func scheduleRefillNotification(for medication: LunixiaMedication, refillDate: Date) {
        guard let fireDate = Calendar.current.date(
            byAdding: .day,
            value: -medication.daysBeforeRefillNotify,
            to: Calendar.current.startOfDay(for: refillDate)
        ), fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(medication.name) refill coming up"
        content.body = "Your refill is due in \(medication.daysBeforeRefillNotify) day\(medication.daysBeforeRefillNotify == 1 ? "" : "s")."
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: refillID(medication), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - IDs

    private func doseID(_ med: LunixiaMedication, timeIndex: Int, weekday: Int) -> String {
        "lunixia.med.dose.t\(timeIndex).wd\(weekday).\(med.id.uuidString)"
    }

    private func doseDefaultID(_ med: LunixiaMedication, timeIndex: Int) -> String {
        "lunixia.med.dose.t\(timeIndex).default.\(med.id.uuidString)"
    }

    private func refillID(_ med: LunixiaMedication) -> String {
        "lunixia.med.refill.\(med.id.uuidString)"
    }
}
