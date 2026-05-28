//
//  JournalCardBlockPreviewSupport.swift
//  Lunixia
//

import Foundation

extension JournalEntry {
    var preferredCardPreviewText: String {
        blockPreviewText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
