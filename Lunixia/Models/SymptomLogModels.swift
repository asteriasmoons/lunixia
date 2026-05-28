//
//  SymptomLogModels.swift
//  Lunixia
//

import Foundation
import SwiftData
@Model
final class LunixiaSymptomLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    /// JSON-encoded [String]
    var symptomsStorage: String = "[]"

    /// Severity 1–5, 0 = not set
    var severity: Int = 0

    /// Optional note
    var note: String = ""

    var symptoms: [String] {
        get {
            guard let data = symptomsStorage.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let encoded = String(data: data, encoding: .utf8) {
                symptomsStorage = encoded
            } else {
                symptomsStorage = "[]"
            }
        }
    }

    static let allSymptoms: [String] = [
        // Head
        "headache", "migraine", "brain fog", "dizziness",
        // Body
        "fatigue", "nausea", "chills", "fever", "sweating",
        "muscle aches", "joint pain", "back pain", "chest tightness",
        "shortness of breath",
        // Digestive
        "bloating", "cramps", "stomach ache", "heartburn",
        "constipation", "diarrhea", "appetite loss",
        // Respiratory
        "sore throat", "congestion", "coughing",
        // Hormonal / cycle
        "pms", "spotting", "heavy flow", "breast tenderness",
        // Skin
        "breakout", "rash", "itching", "dry skin",
        // Sleep
        "insomnia", "oversleeping",
        // Mental / emotional
        "anxiety", "low mood", "irritability", "overwhelm",
        "low energy", "mood swings"
    ]

    static let severityLabels: [Int: String] = [
        1: "Mild",
        2: "Noticeable",
        3: "Moderate",
        4: "Significant",
        5: "Severe"
    ]

    init(
        symptoms: [String],
        severity: Int = 0,
        note: String = "",
        date: Date = Date()
    ) {
        self.id = UUID()
        self.date = date
        self.createdAt = Date()
        self.updatedAt = Date()
        self.severity = severity
        self.note = note
        self.symptomsStorage = "[]"
        self.symptoms = symptoms
    }
}
