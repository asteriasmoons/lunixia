//
//  JournalInlineStyle.swift
//  Lunixia
//

import Foundation
import SwiftData

enum JournalInlineStyleType: String, Codable, CaseIterable {
    case bold
    case italic
    case underline
    case strikethrough
    case link
    case inlineCode
    case highlight
    case mention // urlString stores JournalBook persistentModelID string
}

@Model
final class JournalInlineStyle {
    var id: UUID = UUID()

    var typeRaw: String = JournalInlineStyleType.bold.rawValue
    var rangeLocation: Int = 0
    var rangeLength: Int = 0
    var urlString: String = ""

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(inverse: \JournalBlock.inlineStyles)
    var block: JournalBlock?

    init(
        type: JournalInlineStyleType = .bold,
        rangeLocation: Int = 0,
        rangeLength: Int = 0,
        urlString: String = ""
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.rangeLocation = rangeLocation
        self.rangeLength = rangeLength
        self.urlString = urlString
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var type: JournalInlineStyleType {
        get { JournalInlineStyleType(rawValue: typeRaw) ?? .bold }
        set { typeRaw = newValue.rawValue }
    }

    var safeRange: NSRange {
        NSRange(location: max(0, rangeLocation), length: max(0, rangeLength))
    }

    func touch() {
        updatedAt = Date()
    }
}
