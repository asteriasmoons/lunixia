//
//  MedicationAutomationManager.swift
//  Lunixia
//

import Foundation
import SwiftData

@MainActor
enum MedicationAutomationManager {

    // MARK: - Public API

    static func run(
        in modelContext: ModelContext,
        now: Date = Date()
    ) {
        do {
            let descriptor = FetchDescriptor<LunixiaMedication>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )

            let medications = try modelContext.fetch(descriptor)

            processRefills(
                medications: medications,
                modelContext: modelContext,
                now: now
            )

            processAutoDecreases(
                medications: medications,
                modelContext: modelContext,
                now: now
            )

            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            print("[MedicationAutomationManager] Automation failed: \(error)")
        }
    }

    static func dayKey(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.string(from: day)
    }

    // MARK: - Refills

    private static func processRefills(
        medications: [LunixiaMedication],
        modelContext: ModelContext,
        now: Date
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let todayKey = dayKey(for: today)

        for medication in medications {
            guard medication.isActive,
                  let refillDate = medication.refillDate,
                  calendar.startOfDay(for: refillDate) <= today,
                  medication.lastAutoRefillDayKey != todayKey else {
                continue
            }

            let previousAmount = medication.currentAmount

            medication.currentAmount = max(0, medication.supplyAmount)
            medication.lastAutoRefillDayKey = todayKey
            medication.updatedAt = now

            if medication.daysSupply > 0 {
                medication.refillDate = calendar.date(
                    byAdding: .day,
                    value: medication.daysSupply,
                    to: calendar.startOfDay(for: refillDate)
                )
            }

            modelContext.insert(
                LunixiaMedHistoryEntry(
                    type: .refilled,
                    amountText: "\(previousAmount) → \(medication.currentAmount)",
                    details: medication.daysSupply > 0
                        ? "Auto-refilled on refill date. Next refill in \(medication.daysSupply) days."
                        : "Auto-refilled on refill date.",
                    medication: medication
                )
            )

            MedicationNotificationManager.shared.reschedule(for: medication)
        }
    }

    // MARK: - Auto Decrease

    private static func processAutoDecreases(
        medications: [LunixiaMedication],
        modelContext: ModelContext,
        now: Date
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let todayKey = dayKey(for: today)

        for medication in medications {
            guard medication.isActive,
                  medication.autoDecreaseEnabled else {
                continue
            }

            if medication.lastAutoDecreaseDayKey.isEmpty {
                medication.lastAutoDecreaseDayKey = todayKey
                medication.updatedAt = now
                continue
            }

            guard let lastProcessedDay = date(
                fromDayKey: medication.lastAutoDecreaseDayKey
            ) else {
                medication.lastAutoDecreaseDayKey = todayKey
                medication.updatedAt = now
                continue
            }

            guard let firstUnprocessedDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: lastProcessedDay
            ),
            firstUnprocessedDay <= today else {
                continue
            }

            var dayToProcess = firstUnprocessedDay

            while dayToProcess <= today {
                let isToday = calendar.isDate(
                    dayToProcess,
                    inSameDayAs: today
                )

                if isToday {
                    let scheduledTime = automationTime(
                        for: medication,
                        on: dayToProcess
                    )

                    if now < scheduledTime {
                        break
                    }
                }

                let doses = scheduledDoseCount(
                    for: medication,
                    on: dayToProcess
                )

                let processedDayKey = dayKey(for: dayToProcess)

                if doses > 0 {
                    let previousAmount = medication.currentAmount
                    let newAmount = max(0, previousAmount - doses)

                    medication.currentAmount = newAmount

                    let formattedDay = dayToProcess.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )

                    let details: String

                    if isToday {
                        details = doses > 1
                            ? "Auto-decreased by today’s scheduled \(doses) doses."
                            : "Auto-decreased by today’s scheduled dose."
                    } else {
                        details = doses > 1
                            ? "Backfilled \(doses) scheduled doses for \(formattedDay)."
                            : "Backfilled scheduled dose for \(formattedDay)."
                    }

                    modelContext.insert(
                        LunixiaMedHistoryEntry(
                            type: .taken,
                            amountText: "\(previousAmount) → \(newAmount)",
                            details: details,
                            medication: medication
                        )
                    )
                }

                medication.lastAutoDecreaseDayKey = processedDayKey
                medication.updatedAt = now

                guard let nextDay = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: dayToProcess
                ) else {
                    break
                }

                dayToProcess = nextDay
            }
        }
    }

    // MARK: - Schedule Helpers

    private static func date(fromDayKey dayKey: String) -> Date? {
        let calendar = Calendar.current

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        guard let parsedDate = formatter.date(from: dayKey) else {
            return nil
        }

        return calendar.startOfDay(for: parsedDate)
    }

    private static func automationTime(
        for medication: LunixiaMedication,
        on day: Date
    ) -> Date {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)

        let hour = min(max(medication.autoDecreaseHour, 0), 23)
        let minute = min(max(medication.autoDecreaseMinute, 0), 59)

        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: dayStart
        ) ?? dayStart
    }

    private static func scheduledDoseCount(
        for medication: LunixiaMedication,
        on day: Date
    ) -> Int {
        let weekday = Calendar.current.component(.weekday, from: day)

        switch medication.scheduleFrequency {
        case .daily:
            let amount = medication.doseScheduleOverrides[weekday]
                ?? medication.timesPerDay

            return max(0, amount)

        case .weekly:
            guard weekday == medication.weeklyWeekday else {
                return 0
            }

            return max(0, medication.timesPerDay)
        }
    }
}
