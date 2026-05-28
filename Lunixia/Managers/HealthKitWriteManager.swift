//
//  HealthKitWriteManager.swift
//  Lunixia
//

import Foundation
import HealthKit

final class HealthKitWriteManager {
    static let shared = HealthKitWriteManager()
    private let store = HKHealthStore()
    private init() {}

    // MARK: - Authorization for writing

    func requestWriteAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
        ]

        let readTypes: Set<HKObjectType> = writeTypes.compactMap { $0 as? HKObjectType }.reduce(into: Set<HKObjectType>()) { $0.insert($1) }

        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
        } catch {
            print("HealthKit write auth error: \(error)")
        }
    }

    // MARK: - Write Vitals

    func writeVitals(entry: VitalsEntry) async {
        let date = entry.timestamp
        var samples: [HKSample] = []

        // Blood Oxygen
        if entry.bloodOxygen > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) {
            let qty = HKQuantity(unit: .percent(), doubleValue: entry.bloodOxygen / 100)
            samples.append(HKQuantitySample(type: type, quantity: qty, start: date, end: date))
        }

        // Heart Rate
        if entry.bpm > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let qty = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: entry.bpm)
            samples.append(HKQuantitySample(type: type, quantity: qty, start: date, end: date))
        }

        // Blood Pressure (systolic + diastolic must be written as a correlation)
        if entry.systolic > 0 && entry.diastolic > 0,
           let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
           let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic),
           let bpType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure) {
            let systolicSample = HKQuantitySample(
                type: systolicType,
                quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: entry.systolic),
                start: date, end: date
            )
            let diastolicSample = HKQuantitySample(
                type: diastolicType,
                quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: entry.diastolic),
                start: date, end: date
            )
            let correlation = HKCorrelation(
                type: bpType,
                start: date,
                end: date,
                objects: [systolicSample, diastolicSample]
            )
            samples.append(correlation)
        }

        // Body Temperature
        if entry.bodyTemp > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) {
            let tempC = (entry.bodyTemp - 32) * 5 / 9
            let qty = HKQuantity(unit: .degreeCelsius(), doubleValue: tempC)
            samples.append(HKQuantitySample(type: type, quantity: qty, start: date, end: date))
        }

        // Weight
        if entry.weight > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let qty = HKQuantity(unit: .pound(), doubleValue: entry.weight)
            samples.append(HKQuantitySample(type: type, quantity: qty, start: date, end: date))
        }

        do {
            try await store.save(samples)
        } catch {
            print("HealthKit vitals write error: \(error)")
        }
    }

    // MARK: - Write Exercise

    func writeExercise(entry: ExerciseEntry) async {
        let start = entry.timestamp
        let end = start.addingTimeInterval(Double(entry.durationMinutes) * 60)

        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: start,
            end: end,
            duration: Double(entry.durationMinutes) * 60,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: [
                HKMetadataKeyWorkoutBrandName: entry.name,
                "reps": entry.reps
            ]
        )

        do {
            try await store.save(workout)
        } catch {
            print("HealthKit exercise write error: \(error)")
        }
    }

    // MARK: - Write Water

    func writeWater(oz: Double) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        let qty = HKQuantity(unit: .fluidOunceUS(), doubleValue: oz)
        let sample = HKQuantitySample(type: type, quantity: qty, start: Date(), end: Date())
        do {
            try await store.save(sample)
        } catch {
            print("HealthKit water write error: \(error)")
        }
    }
}
