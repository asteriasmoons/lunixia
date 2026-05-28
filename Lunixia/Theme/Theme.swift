//
//  Theme.swift
//  Lunixia
//

import SwiftUI

// MARK: - Color Tokens

enum LColors {
    // Base
    static let bg = Color(lunixiaHex: "#020304")
    static let bgSoft = Color(lunixiaHex: "#07070a")
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(lunixiaHex: "#888888")
    
    // Accent
    static let accent = Color(lunixiaHex: "#03dbfc")
    static let accentHover = Color(lunixiaHex: "#7d19f7")
    static let accentGradient = LinearGradient(
        colors: [
            Color(lunixiaHex: "#03dbfc"),
            Color(lunixiaHex: "#7d19f7")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Status
    static let success = Color(lunixiaHex: "#e2ed8a")
    static let danger = Color(lunixiaHex: "#dc3beb")
    static let warning = Color(lunixiaHex: "#a92ce8")
    
    // Glass surfaces
    static let glassSurface = Color.white.opacity(0.06)
    static let glassSurface2 = Color.white.opacity(0.09)
    static let glassBorder = Color.white.opacity(0.14)
    static let glassBorderStrong = Color.white.opacity(0.22)
    
    // Gradient colors
    static let gradientPurple = Color(lunixiaHex: "#7d19f7")
    static let gradientBlue = Color(lunixiaHex: "#03dbfc")
    static let gradientCyan = Color(lunixiaHex: "#00dbff")
    static let gradientYellow = Color(lunixiaHex: "#f6f684")
    static let gradientDeepPurple = Color(lunixiaHex: "#8000fe")
    
    // Badge colors
    static let badgeOnce = Color(lunixiaHex: "#66b8ff")
    static let badgeDaily = Color(lunixiaHex: "#7d19f7")
    static let badgeWeekly = Color.white
    static let badgeInterval = Color(lunixiaHex: "#02edd6")
}

// MARK: - Gradients

enum LGradients {
    static let blue = LinearGradient(
        colors: [LColors.gradientBlue, LColors.gradientPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let header = LinearGradient(
        colors: [LColors.gradientPurple, LColors.gradientBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let tag = LinearGradient(
        colors: [LColors.gradientPurple, LColors.gradientBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Background ambient glows
    static let bgPurple = RadialGradient(
        colors: [Color(lunixiaHex: "#8000fe").opacity(0.34), .clear],
        center: UnitPoint(x: 0.28, y: 0.18),
        startRadius: 0,
        endRadius: 450
    )
    
    static let bgCyan = RadialGradient(
        colors: [Color(lunixiaHex: "#00dbff").opacity(0.22), .clear],
        center: UnitPoint(x: 0.76, y: 0.78),
        startRadius: 0,
        endRadius: 475
    )
    
    static let bgYellow = RadialGradient(
        colors: [Color(lunixiaHex: "#f6f684").opacity(0.22), .clear],
        center: UnitPoint(x: 0.58, y: 0.26),
        startRadius: 0,
        endRadius: 260
    )
}

// MARK: - Spacing & Radius

enum LSpacing {
    static let cardPadding: CGFloat = 20
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let inputRadius: CGFloat = 12
    static let pillRadius: CGFloat = 999
    static let pageHorizontal: CGFloat = 16
    static let sectionGap: CGFloat = 24
}

// MARK: - Color Extension

extension Color {
    init(lunixiaHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch hex.count {
        case 6:
            (a, r, g, b) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        case 8:
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
