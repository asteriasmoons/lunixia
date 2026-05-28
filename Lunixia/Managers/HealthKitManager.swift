//
//  HealthKitManager.swift
//  Lunixia
//

import Foundation
import HealthKit
import SwiftData

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    var isAuthorized = false
    private(set) var hasFetchedToday = false

    var sleepHours: Double = 0
    var exerciseMinutes: Int = 0
    var steps: Int = 0
    var meditationMinutes: Int = 0
    var cycleNote: String = ""
    var waterOz: Double = 0
    var caffeineMg: Double = 0
    var bpm: Double = 0

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let shareTypes: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.categoryType(forIdentifier: .menstrualFlow)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
        ]

        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            isAuthorized = true
        } catch {
            print("HealthKit auth error: \(error)")
            isAuthorized = false
        }
    }

    @MainActor
    func requestAuthorizationIfNeeded(settings: UserSettings) async {
        guard !settings.didRequestHealthKitAuthorization else { return }
        
        await requestAuthorization()
        settings.didRequestHealthKitAuthorization = true
        settings.updatedAt = Date()
    }

    // MARK: - Fetch All

    func fetchAll() async {
        if !isAuthorized {
            await requestAuthorization()
        }

        let todayStart = Calendar.current.startOfDay(for: Date())
        let now = Date()
        let todayPredicate = HKQuery.predicateForSamples(withStart: todayStart, end: now)

        async let s  = fetchSleep(todayStart: todayStart, now: now)
        async let e  = fetchExercise(predicate: todayPredicate)
        async let st = fetchSteps(predicate: todayPredicate)
        async let m  = fetchMeditation(predicate: todayPredicate)
        async let c  = fetchCycle(predicate: todayPredicate)
        async let w  = fetchWater(predicate: todayPredicate)
        async let ca = fetchCaffeine(predicate: todayPredicate)
        async let hr = fetchHeartRate(predicate: todayPredicate)

        let (sleep, exercise, stepsVal, meditation, cycle, water, caffeine, heartRate) =
            await (s, e, st, m, c, w, ca, hr)

        await MainActor.run {
            self.sleepHours        = sleep
            self.exerciseMinutes   = exercise
            self.steps             = stepsVal
            self.meditationMinutes = meditation
            self.cycleNote         = cycle
            self.waterOz           = water
            self.caffeineMg        = caffeine
            self.bpm               = heartRate
            self.hasFetchedToday   = true
        }
    }

    // MARK: - Write Mindful Minutes

    func addMindfulMinutesForJournalEntry(minutes: Int = 1, at date: Date = Date()) async {
        print("[HealthKit] addMindfulMinutes start minutes=\(minutes)")
        guard HKHealthStore.isHealthDataAvailable() else { print("[HealthKit] HealthData not available"); return }
        guard minutes > 0 else { return }
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }

        if !isAuthorized {
            print("[HealthKit] not authorized, requesting")
            await requestAuthorization()
        }

        let endDate = date
        let startDate = Calendar.current.date(byAdding: .minute, value: -minutes, to: endDate) ?? endDate.addingTimeInterval(Double(-minutes * 60))

        let sample = HKCategorySample(
            type: type,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )

        do {
            print("[HealthKit] saving mindful sample")
            try await store.save(sample)
            print("[HealthKit] mindful sample saved")
            await MainActor.run {
                self.hasFetchedToday = false
            }
        } catch {
            print("[HealthKit] mindful journal save error: \(error)")
        }
        print("[HealthKit] addMindfulMinutes done")
    }

    // MARK: - Sleep
    // Previous noon → current noon to capture a full night within "today"

    private func fetchSleep(todayStart: Date, now: Date) async -> Double {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let calendar = Calendar.current
        let todayNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let yesterdayNoon = calendar.date(byAdding: .day, value: -1, to: todayNoon) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: yesterdayNoon, end: now)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0); return
                }
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let total = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: total / 3600)
            }
            store.execute(query)
        }
    }

    // MARK: - Exercise

    private func fetchExercise(predicate: NSPredicate) async -> Int {
        var exerciseRingMinutes = 0

        if let type = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            exerciseRingMinutes = Int(await fetchSum(type: type, unit: .minute(), predicate: predicate))
        }

        let workoutMinutes = await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    print("HealthKit workout fetch error: \(error)")
                    continuation.resume(returning: 0)
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: 0)
                    return
                }

                let total = workouts.reduce(0.0) { $0 + $1.duration }
                continuation.resume(returning: Int(total / 60))
            }
            store.execute(query)
        }

        return max(exerciseRingMinutes, workoutMinutes)
    }

    // MARK: - Steps

    private func fetchSteps(predicate: NSPredicate) async -> Int {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return 0 }
        return Int(await fetchSum(type: type, unit: .count(), predicate: predicate))
    }

    // MARK: - Meditation

    private func fetchMeditation(predicate: NSPredicate) async -> Int {
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return 0 }

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0); return
                }
                let total = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: Int(total / 60))
            }
            store.execute(query)
        }
    }

    // MARK: - Cycle

    private func fetchCycle(predicate: NSPredicate) async -> String {
        guard let type = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else { return "" }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKCategorySample else {
                    continuation.resume(returning: ""); return
                }
                let flow: String
                switch HKCategoryValueMenstrualFlow(rawValue: sample.value) {
                case .none:        flow = "no flow"
                case .unspecified: flow = "spotting"
                case .light:       flow = "light"
                case .medium:      flow = "medium"
                case .heavy:       flow = "heavy"
                @unknown default:  flow = "logged"
                }
                continuation.resume(returning: flow)
            }
            store.execute(query)
        }
    }

    // MARK: - Water

    private func fetchWater(predicate: NSPredicate) async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .dietaryWater) else { return 0 }
        return await fetchSum(type: type, unit: .fluidOunceUS(), predicate: predicate)
    }

    // MARK: - Caffeine

    private func fetchCaffeine(predicate: NSPredicate) async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine) else { return 0 }
        return await fetchSum(type: type, unit: .gramUnit(with: .milli), predicate: predicate)
    }

    // MARK: - Heart Rate

    private func fetchHeartRate(predicate: NSPredicate) async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return 0 }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    print("HealthKit heart rate error: \(error)")
                    continuation.resume(returning: 0)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }

                let unit = HKUnit.count().unitDivided(by: .minute())
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }

            store.execute(query)
        }
    }

    // MARK: - Helper

    private func fetchSum(type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async -> Double {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    private func fetchSampleSum(type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    print("HealthKit sample sum error for \(type.identifier): \(error)")
                    continuation.resume(returning: 0)
                    return
                }

                let quantitySamples = samples as? [HKQuantitySample] ?? []
                let total = quantitySamples.reduce(0.0) { partialResult, sample in
                    partialResult + sample.quantity.doubleValue(for: unit)
                }

                continuation.resume(returning: total)
            }

            store.execute(query)
        }
    }

    // MARK: - Public standalone steps fetch for Health tab

    func fetchStepsToday() async -> Int {
        if !isAuthorized {
            await requestAuthorization()
        }

        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return Int(await fetchSum(type: type, unit: .count(), predicate: predicate))
    }

    func fetchWaterToday() async -> Double {
        if !isAuthorized {
            await requestAuthorization()
        }

        guard let type = HKObjectType.quantityType(forIdentifier: .dietaryWater) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let total = await fetchSum(type: type, unit: .fluidOunceUS(), predicate: predicate)

        await MainActor.run {
            self.waterOz = total
        }

        return total
    }

    func fetchHeartRateToday() async -> Double {

        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let heartRate = await fetchHeartRate(predicate: predicate)

        await MainActor.run {
            self.bpm = heartRate
        }

        return heartRate
    }
}
