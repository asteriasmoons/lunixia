//
//  MoonPhaseCalculator.swift
//  Lunixia
//

import Foundation

struct MoonPhaseCalculator {
    private static let synodicMonth = 29.530588853
    private static let newMoonEpochJD = 2451550.09765
    private static let zodiacSigns = [
        "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
        "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
    ]

    // Tuning knobs carried over from the Scriptable version.
    private static let avoidDisplaying100 = true
    private static let illuminationDisplayNudge = 0.0005
    private static let moonDayOffsetHours = 0.0

    static func calculate(for date: Date = Date()) -> MoonPhaseData {
        let phaseName = getMoonPhaseName(for: date)
        let signName = getMoonSign(for: date)
        let moonDay = getMoonDayNumber(for: date)
        let moonAgeDays = getMoonAgeDays(for: date)
        let elongationDegrees = getElongationDegrees(for: date)
        let rawIlluminationFraction = getIlluminationFraction(for: date)
        let displayIlluminationFraction = smoothedIlluminationFraction(from: rawIlluminationFraction)
        let moonEclipticLongitude = getMoonEclipticLongitude(for: date)

        return MoonPhaseData(
            date: date,
            phaseName: phaseName,
            signName: signName,
            moonDay: moonDay,
            illuminationFraction: displayIlluminationFraction,
            illuminationPercent: displayIlluminationFraction * 100,
            moonAgeDays: moonAgeDays,
            elongationDegrees: elongationDegrees,
            moonEclipticLongitude: moonEclipticLongitude
        )
    }

    static func getMoonPhaseAndSignString(for date: Date = Date()) -> String {
        calculate(for: date).multilineDisplayString
    }

    static func getMoonPhaseName(for date: Date = Date()) -> String {
        let e = getElongationDegrees(for: date)

        let newWindow = 6.0
        let quarterWindow = 6.0
        let fullWindow = 6.0

        if isNear(e, center: 0, width: newWindow) { return "New Moon" }
        if isNear(e, center: 90, width: quarterWindow) { return "First Quarter" }
        if isNear(e, center: 180, width: fullWindow) { return "Full Moon" }
        if isNear(e, center: 270, width: quarterWindow) { return "Last Quarter" }

        if e > 0 && e < 90 { return "Waxing Crescent" }
        if e > 90 && e < 180 { return "Waxing Gibbous" }
        if e > 180 && e < 270 { return "Waning Gibbous" }
        return "Waning Crescent"
    }

    static func getMoonSign(for date: Date = Date()) -> String {
        let moonLongitude = getMoonEclipticLongitude(for: date)
        let index = min(Int(floor(moonLongitude / 30.0)), zodiacSigns.count - 1)
        return zodiacSigns[max(0, index)]
    }

    static func getMoonDayNumber(for date: Date = Date()) -> Int {
        Int(floor(getMoonAgeDays(for: date))) + 1
    }

    static func getMoonAgeDays(for date: Date = Date()) -> Double {
        let adjustedDate = moonDayOffsetHours == 0 ? date : addHours(moonDayOffsetHours, to: date)
        let julianDay = toJulianDay(adjustedDate)

        let k0 = Int(round((julianDay - newMoonEpochJD) / synodicMonth))

        let nm0 = newMoonJDE(k: Double(k0))
        let nmPrev = newMoonJDE(k: Double(k0 - 1))
        let nmNext = newMoonJDE(k: Double(k0 + 1))

        let lastNewMoon: Double
        if nm0 > julianDay {
            lastNewMoon = nmPrev
        } else if nmNext <= julianDay {
            lastNewMoon = nmNext
        } else {
            lastNewMoon = nm0
        }

        var age = julianDay - lastNewMoon
        age.formTruncatingRemainder(dividingBy: synodicMonth)
        if age < 0 {
            age += synodicMonth
        }
        return age
    }

    static func getMoonEclipticLongitude(for date: Date = Date()) -> Double {
        let julianDay = toJulianDay(date)
        let d = julianDay - 2451545.0

        let L = norm360(218.316 + 13.176396 * d)
        let Mm = norm360(134.963 + 13.064993 * d)
        let Ms = norm360(357.529 + 0.98560028 * d)
        let D = norm360(297.850 + 12.190749 * d)
        let F = norm360(93.272 + 13.229350 * d)

        let longitude =
            L +
            6.289 * sinDeg(Mm) +
            1.274 * sinDeg(2 * D - Mm) +
            0.658 * sinDeg(2 * D) +
            0.214 * sinDeg(2 * Mm) -
            0.186 * sinDeg(Ms) -
            0.114 * sinDeg(2 * F)

        return norm360(longitude)
    }

    static func getIlluminationFraction(for date: Date = Date()) -> Double {
        let elongation = getElongationDegrees(for: date)
        return clamp01(0.5 * (1 - cos(deg2rad(elongation))))
    }

    static func getElongationDegrees(for date: Date = Date()) -> Double {
        let moonLongitude = getMoonEclipticLongitude(for: date)
        let sunLongitude = getSunEclipticLongitude(for: date)
        return norm360(moonLongitude - sunLongitude)
    }

    static func getSunEclipticLongitude(for date: Date = Date()) -> Double {
        let julianDay = toJulianDay(date)
        let n = julianDay - 2451545.0

        let L = norm360(280.460 + 0.9856474 * n)
        let g = norm360(357.528 + 0.9856003 * n)

        let lambda =
            L +
            1.915 * sinDeg(g) +
            0.020 * sinDeg(2 * g)

        return norm360(lambda)
    }

    private static func newMoonJDE(k: Double) -> Double {
        let T = k / 1236.85
        let T2 = T * T
        let T3 = T2 * T
        let T4 = T3 * T

        var jde =
            2451550.09765 +
            29.530588853 * k +
            0.0001337 * T2 -
            0.000000150 * T3 +
            0.00000000073 * T4

        let M =
            2.5534 +
            29.10535670 * k -
            0.0000014 * T2 -
            0.00000011 * T3

        let Mp =
            201.5643 +
            385.81693528 * k +
            0.0107582 * T2 +
            0.00001238 * T3 -
            0.000000058 * T4

        let F =
            160.7108 +
            390.67050284 * k -
            0.0016118 * T2 -
            0.00000227 * T3 +
            0.000000011 * T4

        let omega =
            124.7746 -
            1.56375588 * k +
            0.0020672 * T2 +
            0.00000215 * T3

        let E = 1 - 0.002516 * T - 0.0000074 * T2

        jde +=
            -0.40720 * sinDeg(Mp) +
            0.17241 * E * sinDeg(M) +
            0.01608 * sinDeg(2 * Mp) +
            0.01039 * sinDeg(2 * F) +
            0.00739 * E * sinDeg(Mp - M) -
            0.00514 * E * sinDeg(Mp + M) +
            0.00208 * E * E * sinDeg(2 * M) -
            0.00111 * sinDeg(Mp - 2 * F) -
            0.00057 * sinDeg(Mp + 2 * F) +
            0.00056 * E * sinDeg(2 * Mp + M) -
            0.00042 * sinDeg(3 * Mp) +
            0.00042 * E * sinDeg(M + 2 * F) +
            0.00038 * E * sinDeg(M - 2 * F) -
            0.00024 * E * sinDeg(2 * Mp - M) -
            0.00017 * sinDeg(omega)

        return jde
    }

    private static func smoothedIlluminationFraction(from fraction: Double) -> Double {
        guard avoidDisplaying100, fraction >= 0.9995 else { return fraction }
        return max(0, fraction - illuminationDisplayNudge)
    }

    private static func isNear(_ value: Double, center: Double, width: Double) -> Bool {
        var distance = abs(value - center)
        if distance > 180 {
            distance = 360 - distance
        }
        return distance <= width
    }

    private static func toJulianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    private static func norm360(_ degrees: Double) -> Double {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        return normalized < 0 ? normalized + 360 : normalized
    }

    private static func clamp01(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private static func deg2rad(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private static func sinDeg(_ degrees: Double) -> Double {
        sin(deg2rad(degrees))
    }

    private static func addHours(_ hours: Double, to date: Date) -> Date {
        date.addingTimeInterval(hours * 3600)
    }
}
