//
//  StoredHoroscope.swift
//  Lunixia
//

import Foundation

struct StoredDailyHoroscope: Codable, Equatable {
    let dayKey: String
    let horoscope: DailyHoroscope
}
