//
//  JournalBlock.swift
//  Lunixia
//

import Foundation
import SwiftData

enum JournalBlockType: String, Codable, CaseIterable {
    case paragraph
    case heading1
    case heading2
    case heading3
    case heading4
    case heading5
    case heading6
    case toggleHeading1
    case toggleHeading2
    case toggleHeading3
    case toggleHeading4
    case toggleHeading5
    case toggleHeading6
    case blockquote
    case callout
    case divider
    case code
    case image
    case table
    case toggle
    case bulletedList
    case numberedList
    case checklist

    var isToggleHeading: Bool {
        switch self {
        case .toggleHeading1, .toggleHeading2, .toggleHeading3,
             .toggleHeading4, .toggleHeading5, .toggleHeading6: return true
        default: return false
        }
    }
}

@Model
final class JournalBlock {
    var id: UUID = UUID()

    // CloudKit-safe defaults
    var typeRaw: String = JournalBlockType.paragraph.rawValue
    var text: String = ""
    var sortOrder: Int = 0

    // Structure for real lists & toggles
    var parentBlockID: UUID? = nil
    var listGroupID: UUID? = nil
    var isExpanded: Bool = true
    var indentLevel: Int = 0

    // Blockquote / callout overlay styles
    var isBlockquoteStyle: Bool = false
    var isCalloutStyle: Bool = false

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Optional metadata, but stored CloudKit-safe with defaults
    var calloutEmoji: String = ""
    var languageHint: String = ""

    // Per-block accent color overrides — stored as "RRGGBB:RRGGBB" (two-stop gradient)
    // Empty string = use default LGradients.blue
    var dividerColorHex: String = ""
    var blockquoteColorHex: String = ""
    var calloutColorHex: String = ""

    // Image block data. languageHint stores alignment: "" = left, "center" = center.
    var imageData: Data? = nil

    var entry: JournalEntry?

    var inlineStyles: [JournalInlineStyle]? = nil

    init(
        type: JournalBlockType = .paragraph,
        text: String = "",
        sortOrder: Int = 0,
        parentBlockID: UUID? = nil,
        listGroupID: UUID? = nil,
        isExpanded: Bool = true,
        indentLevel: Int = 0,
        isBlockquoteStyle: Bool = false,
        isCalloutStyle: Bool = false,
        calloutEmoji: String = "",
        languageHint: String = "",
        imageData: Data? = nil
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.text = text
        self.sortOrder = sortOrder
        self.parentBlockID = parentBlockID
        self.listGroupID = listGroupID
        self.isExpanded = isExpanded
        self.indentLevel = indentLevel
        self.isBlockquoteStyle = isBlockquoteStyle
        self.isCalloutStyle = isCalloutStyle
        self.createdAt = Date()
        self.updatedAt = Date()
        self.calloutEmoji = calloutEmoji
        self.languageHint = languageHint
        self.imageData = imageData
    }

    var type: JournalBlockType {
        get { JournalBlockType(rawValue: typeRaw) ?? .paragraph }
        set { typeRaw = newValue.rawValue }
    }

    var isListBlock: Bool {
        switch type {
        case .bulletedList, .numberedList, .checklist:
            return true
        default:
            return false
        }
    }

    var isToggleBlock: Bool {
        type == .toggle
    }

    // languageHint stores pipe-separated image options: "alignment|size|displayMode"
    // e.g. "center|medium|fit", "|large|fill", "|small|fit"
    // Defaults: left, medium, fit

    private var imageParts: [String] {
        let parts = languageHint.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        return [
            parts.count > 0 ? parts[0] : "",
            parts.count > 1 ? parts[1] : "",
            parts.count > 2 ? parts[2] : ""
        ]
    }

    private func setImagePart(_ index: Int, value: String) {
        var parts = imageParts
        parts[index] = value
        languageHint = parts.joined(separator: "|")
    }

    var imageAlignment: ImageBlockAlignment {
        get { ImageBlockAlignment(rawValue: imageParts[0]) ?? .left }
        set { setImagePart(0, value: newValue.rawValue) }
    }

    var imageSize: ImageBlockSize {
        get { ImageBlockSize(rawValue: imageParts[1]) ?? .medium }
        set { setImagePart(1, value: newValue.rawValue) }
    }

    var imageDisplayMode: ImageBlockDisplayMode {
        get { ImageBlockDisplayMode(rawValue: imageParts[2]) ?? .fit }
        set { setImagePart(2, value: newValue.rawValue) }
    }

    var sortedInlineStyles: [JournalInlineStyle] {
        (inlineStyles ?? []).sorted {
            if $0.rangeLocation == $1.rangeLocation {
                return $0.rangeLength < $1.rangeLength
            }
            return $0.rangeLocation < $1.rangeLocation
        }
    }

    func touch() {
        updatedAt = Date()
    }
}

// MARK: - Image Block Supporting Types

enum ImageBlockAlignment: String {
    case left = ""
    case center = "center"
}

enum ImageBlockSize: String, CaseIterable {
    case small  = "small"   // ~380pt tall
    case medium = "medium"  // ~520pt tall
    case large  = "large"   // ~680pt tall
    case full   = "full"    // scaledToFit, unconstrained

    var maxHeight: CGFloat? {
        switch self {
        case .small:  return 380
        case .medium: return 520
        case .large:  return 680
        case .full:   return nil
        }
    }

    var label: String {
        switch self {
        case .small:  return "S"
        case .medium: return "M"
        case .large:  return "L"
        case .full:   return "Full"
        }
    }
}

enum ImageBlockDisplayMode: String {
    case fit  = "fit"   // shows whole image, letterboxed
    case fill = "fill"  // crops to fill the frame

    var label: String {
        switch self {
        case .fit:  return "Fit"
        case .fill: return "Fill"
        }
    }
}
