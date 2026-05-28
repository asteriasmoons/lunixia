//
//  MedicationModels.swift
//  Lunixia
//

import Foundation
import SwiftData

// MARK: - Dose Notify Time

struct DoseNotifyTime: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var hour: Int   // 0–23
    var minute: Int // 0–59

    var displayString: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let m = String(format: "%02d", minute)
        let ampm = hour < 12 ? "AM" : "PM"
        return "\(h):\(m) \(ampm)"
    }
}

// MARK: - Medication

@Model
final class LunixiaMedication {

    // MARK: Core
    var id: UUID = UUID()
    var name: String = ""

    // MARK: Supply
    var currentAmount: Int = 0
    var supplyAmount: Int = 0
    var daysSupply: Int = 0

    // MARK: Refill
    var refillDate: Date? = nil
    var lastAutoRefillDayKey: String = ""

    // MARK: Dose Schedule
    var timesPerDay: Int = 1
    var doseScheduleJSON: String = ""
    var lastTakenAt: Date? = nil

    // MARK: Dose Notifications
    var notifyDose: Bool = false
    /// Legacy single-time fields — retained for CloudKit compatibility, not used in UI.
    var doseNotifyHour: Int = 9
    var doseNotifyMinute: Int = 0
    /// JSON-encoded [DoseNotifyTime] — the authoritative list of reminder times.
    var doseNotifyTimesJSON: String = ""

    // MARK: Refill Notifications
    var notifyRefill: Bool = false
    var daysBeforeRefillNotify: Int = 3

    // MARK: State
    var isActive: Bool = true

    // MARK: Metadata
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \LunixiaMedHistoryEntry.medication)
    var historyEntries: [LunixiaMedHistoryEntry]? = []

    // MARK: - Computed: dose schedule overrides

    var doseScheduleOverrides: [Int: Int] {
        get {
            guard !doseScheduleJSON.isEmpty,
                  let data = doseScheduleJSON.data(using: .utf8),
                  let raw = try? JSONDecoder().decode([String: Int].self, from: data)
            else { return [:] }
            return Dictionary(uniqueKeysWithValues: raw.compactMap { k, v in
                guard let intKey = Int(k) else { return nil }
                return (intKey, v)
            })
        }
        set {
            let stringKeyed = Dictionary(uniqueKeysWithValues: newValue.map { ("\($0.key)", $0.value) })
            if let data = try? JSONEncoder().encode(stringKeyed),
               let str = String(data: data, encoding: .utf8) {
                doseScheduleJSON = str
            } else {
                doseScheduleJSON = ""
            }
        }
    }

    func doses(forWeekday weekday: Int) -> Int {
        doseScheduleOverrides[weekday] ?? timesPerDay
    }

    var dosesToday: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return doses(forWeekday: weekday)
    }

    // MARK: - Computed: dose notify times

    var doseNotifyTimes: [DoseNotifyTime] {
        get {
            guard !doseNotifyTimesJSON.isEmpty,
                  let data = doseNotifyTimesJSON.data(using: .utf8),
                  let times = try? JSONDecoder().decode([DoseNotifyTime].self, from: data)
            else {
                // Fall back to legacy single time if JSON is empty
                return [DoseNotifyTime(hour: doseNotifyHour, minute: doseNotifyMinute)]
            }
            return times.isEmpty ? [DoseNotifyTime(hour: doseNotifyHour, minute: doseNotifyMinute)] : times
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                doseNotifyTimesJSON = str
            } else {
                doseNotifyTimesJSON = ""
            }
        }
    }

    // MARK: - Init

    init(
        name: String,
        currentAmount: Int,
        supplyAmount: Int,
        daysSupply: Int = 0,
        refillDate: Date? = nil,
        timesPerDay: Int = 1,
        doseScheduleOverrides: [Int: Int] = [:],
        notifyDose: Bool = false,
        doseNotifyTimes: [DoseNotifyTime] = [DoseNotifyTime(hour: 9, minute: 0)],
        notifyRefill: Bool = false,
        daysBeforeRefillNotify: Int = 3
    ) {
        self.id = UUID()
        self.name = name
        self.currentAmount = currentAmount
        self.supplyAmount = supplyAmount
        self.daysSupply = daysSupply
        self.refillDate = refillDate
        self.lastAutoRefillDayKey = ""
        self.timesPerDay = timesPerDay
        self.lastTakenAt = nil
        self.notifyDose = notifyDose
        self.doseNotifyHour = doseNotifyTimes.first?.hour ?? 9
        self.doseNotifyMinute = doseNotifyTimes.first?.minute ?? 0
        self.notifyRefill = notifyRefill
        self.daysBeforeRefillNotify = daysBeforeRefillNotify
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
        let stringKeyed = Dictionary(uniqueKeysWithValues: doseScheduleOverrides.map { ("\($0.key)", $0.value) })
        if let data = try? JSONEncoder().encode(stringKeyed),
           let str = String(data: data, encoding: .utf8) {
            self.doseScheduleJSON = str
        } else {
            self.doseScheduleJSON = ""
        }
        if let data = try? JSONEncoder().encode(doseNotifyTimes),
           let str = String(data: data, encoding: .utf8) {
            self.doseNotifyTimesJSON = str
        } else {
            self.doseNotifyTimesJSON = ""
        }
    }
}

// MARK: - History Entry

@Model
final class LunixiaMedHistoryEntry {
    var id: UUID = UUID()
    var typeRaw: String = "taken"
    var amountText: String = ""
    var details: String = ""
    var createdAt: Date = Date()
    var medication: LunixiaMedication?

    enum EntryType: String, Codable {
        case taken    = "taken"
        case refilled = "refilled"
        case edited   = "edited"
    }

    var type: EntryType {
        get { EntryType(rawValue: typeRaw) ?? .taken }
        set { typeRaw = newValue.rawValue }
    }

    init(
        type: EntryType,
        amountText: String,
        details: String,
        createdAt: Date = Date(),
        medication: LunixiaMedication? = nil
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.amountText = amountText
        self.details = details
        self.createdAt = createdAt
        self.medication = medication
    }
}
