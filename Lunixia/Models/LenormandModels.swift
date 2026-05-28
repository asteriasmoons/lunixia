//
//  LenormandModels.swift
//  Lunixia
//

import Foundation
import SwiftData

// MARK: - Lenormand Tip

struct DailyLenormandTip: Codable, Equatable, Hashable, Identifiable {
    let id: String
    let title: String
    let keywords: [String]
    let message: String
}

// MARK: - Daily Lenormand Record

@Model
final class DailyLenormandRecord {
    var dayKey: String = ""
    var tipId: String = ""
    var cardName: String = ""
    var title: String = ""
    var keywordsStorage: String = "[]"
    var message: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var keywords: [String] {
        get {
            guard let data = keywordsStorage.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }

            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let encoded = String(data: data, encoding: .utf8) {
                keywordsStorage = encoded
            } else {
                keywordsStorage = "[]"
            }
        }
    }

    init(
        dayKey: String,
        tipId: String,
        cardName: String,
        title: String,
        keywords: [String],
        message: String
    ) {
        self.dayKey = dayKey
        self.tipId = tipId
        self.cardName = cardName
        self.title = title
        self.keywordsStorage = "[]"
        self.message = message
        self.createdAt = Date()
        self.updatedAt = Date()
        self.keywords = keywords
    }
}

// MARK: - Lenormand Pull History

@Model
final class LenormandPullRecord {
    var id: String = UUID().uuidString
    var cardName: String = ""
    var title: String = ""
    var keywordsStorage: String = "[]"
    var message: String = ""
    var pulledAt: Date = Date()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var keywords: [String] {
        get {
            guard let data = keywordsStorage.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }

            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let encoded = String(data: data, encoding: .utf8) {
                keywordsStorage = encoded
            } else {
                keywordsStorage = "[]"
            }
        }
    }

    init(
        cardName: String,
        title: String,
        keywords: [String],
        message: String,
        pulledAt: Date = Date()
    ) {
        self.id = UUID().uuidString
        self.cardName = cardName
        self.title = title
        self.keywordsStorage = "[]"
        self.message = message
        self.pulledAt = pulledAt
        self.createdAt = Date()
        self.updatedAt = Date()
        self.keywords = keywords
    }
}
