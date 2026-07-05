//
//  LunixiaMoonPhaseWidgetWriter.swift
//  Lunixia
//
//  Mirrors the pattern in LunixiaMoodWidgetWriter.swift:
//  - Main app calculates MoonPhaseData via MoonPhaseCalculator
//  - Encodes it to App Group UserDefaults
//  - Reloads the widget timeline so it picks up fresh data
//

import Foundation
import WidgetKit

enum LunixiaMoonPhaseWidgetWriter {

    private static let widgetDefaults = UserDefaults(suiteName: "group.com.asteriasmoons.Lunixia")
    private static let snapshotKey = "lunixiaMoonPhaseWidgetSnapshot"

    static func write() {
        let data = MoonPhaseCalculator.calculate()

        do {
            let encoded = try JSONEncoder().encode(data)
            widgetDefaults?.set(encoded, forKey: snapshotKey)
            WidgetCenter.shared.reloadTimelines(ofKind: "LunixiaMoonPhaseMediumWidget")
        } catch {
            print("[LunixiaMoonPhaseWidgetWriter] encode error: \(error)")
        }
    }
}
