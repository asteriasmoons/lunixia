//
// MoonPhaseData.swift
// Lunixia
//

import Foundation

struct MoonPhaseData: Equatable {
    let date: Date
    let phaseName: String
    let signName: String
    let moonDay: Int
    let illuminationFraction: Double
    let illuminationPercent: Double
    let moonAgeDays: Double
    let elongationDegrees: Double
    let moonEclipticLongitude: Double

    var headerLine: String {
        "\(phaseName) • \(signName)"
    }

    var detailLine: String {
        "Moon Day \(moonDay) • \(String(format: "%.1f", illuminationPercent))%"
    }

    var multilineDisplayString: String {
        "\(headerLine)\n\(detailLine)"
    }
}
