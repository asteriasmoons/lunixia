//
//  JournalInnerPageStyle.swift
//  Lunixia
//

import SwiftUI
import UIKit

struct JournalInnerPageStyle {

    let entry: JournalEntry

    // MARK: - Fill Layer

    @ViewBuilder
    var fillView: some View {
        switch entry.innerPageBackgroundMode {

        case .defaultGlass:
            Color.black.opacity(entry.innerPageOpacity)

        case .solidColor:
            resolvedSolidColor
                .opacity(entry.innerPageOpacity)

        case .gradient:
            LinearGradient(
                colors: [
                    resolvedGradientStart,
                    resolvedGradientEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(entry.innerPageOpacity)
        }
    }

    // MARK: - Material

    var shouldShowMaterial: Bool {
        entry.innerPageBackgroundMode == .defaultGlass
    }

    // MARK: - Border

    var borderColor: Color {
        Color.white.opacity(0.16)
    }

    // MARK: - Shadow

    var shadowColor: Color {
        Color.black.opacity(0.25)
    }

    // MARK: - Resolved Colors

    private var resolvedSolidColor: Color {
        colorFromHex(entry.innerPageBackgroundColorHex)
    }

    private var resolvedGradientStart: Color {
        colorFromHex(entry.innerPageGradientStartHex)
    }

    private var resolvedGradientEnd: Color {
        colorFromHex(entry.innerPageGradientEndHex)
    }

    // MARK: - Hex Conversion

    private func colorFromHex(_ hex: String) -> Color {

        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 6,
              let value = Int(cleaned, radix: 16) else {
            return Color.black
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        return Color(
            red: red,
            green: green,
            blue: blue
        )
    }
}
