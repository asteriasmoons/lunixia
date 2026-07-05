//
//  HealthModels.swift
//  Lunixia
//

import Foundation
import SwiftData

// MARK: - Vitals Entry

@Model
final class VitalsEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date.now
    var bloodOxygen: Double = 0.0       // %
    var bpm: Double = 0.0               // beats per minute
    var systolic: Double = 0.0          // mmHg
    var diastolic: Double = 0.0         // mmHg
    var bodyTemp: Double = 0.0          // °F
    var weight: Double = 0.0            // lbs

    init(
        bloodOxygen: Double,
        bpm: Double = 0.0,
        systolic: Double,
        diastolic: Double,
        bodyTemp: Double,
        weight: Double,
        timestamp: Date = .now
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.bloodOxygen = bloodOxygen
        self.bpm = bpm
        self.systolic = systolic
        self.diastolic = diastolic
        self.bodyTemp = bodyTemp
        self.weight = weight
    }
}

// MARK: - Exercise Entry

@Model
final class ExerciseEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date.now
    var name: String = ""
    var durationMinutes: Int = 0
    var reps: Int = 0

    init(name: String, durationMinutes: Int, reps: Int, timestamp: Date = .now) {
        self.id = UUID()
        self.timestamp = timestamp
        self.name = name
        self.durationMinutes = durationMinutes
        self.reps = reps
    }
}

// MARK: - Water Log Entry

@Model
final class WaterEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date.now
    var oz: Double = 0.0

    init(oz: Double, timestamp: Date = .now) {
        self.id = UUID()
        self.timestamp = timestamp
        self.oz = oz
    }
}

// MARK: - Health Goals

@Model
final class HealthGoals {
    var id: UUID = UUID()
    var dailyWaterOz: Double = 64.0
    var dailySteps: Int = 10000
    var sleepGoalHours: Double = 8.0

    init(
        dailyWaterOz: Double = 64.0,
        dailySteps: Int = 10000,
        sleepGoalHours: Double = 8.0
    ) {
        self.id = UUID()
        self.dailyWaterOz = dailyWaterOz
        self.dailySteps = dailySteps
        self.sleepGoalHours = sleepGoalHours
    }
}
