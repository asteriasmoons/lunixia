//
//  DailyHoroscope.swift
//  Lunixia
//

import Foundation

struct DailyHoroscope: Codable, Equatable, Hashable {
    let sign: String
    let message: String
}
