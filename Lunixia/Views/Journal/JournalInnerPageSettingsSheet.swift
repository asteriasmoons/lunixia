//
//  JournalInnerPageSettingsSheet.swift
//  Lunixia
//

import SwiftUI
import UIKit

struct JournalInnerPageSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry

    @State private var selectedMode: JournalInnerPageBackgroundMode = .defaultGlass
    @State private var solidColorSelection: Color = .black
    @State private var gradientStartSelection: Color = .black
    @State private var gradientEndSelection: Color = Color(LColors.accent)
    @State private var opacitySelection: Double = 0.34

    var body: some View {
        NavigationStack {
            ZStack {
                LunixiaBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        modeSection
                        colorSection
                        opacitySection
                        previewSection
                        resetSection
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)
                    .padding(.top, 22)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Inner Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        applyChanges()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LColors.textSecondary)
                }
            }
            .onAppear {
                loadExistingValues()
            }
        }
    }

    // MARK: - Sections

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Type")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(LColors.textPrimary)

            Picker("Background Type", selection: $selectedMode) {
                ForEach(JournalInnerPageBackgroundMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var colorSection: some View {
        switch selectedMode {
        case .defaultGlass:
            EmptyView()

        case .solidColor:
            VStack(alignment: .leading, spacing: 14) {
                Text("Solid Color")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LColors.textPrimary)

                ColorPicker("Inner Page Color", selection: $solidColorSelection, supportsOpacity: false)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LColors.textPrimary)
            }
            .settingsCard()

        case .gradient:
            VStack(alignment: .leading, spacing: 14) {
                Text("Gradient Colors")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LColors.textPrimary)

                ColorPicker("Gradient Start", selection: $gradientStartSelection, supportsOpacity: false)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LColors.textPrimary)

                ColorPicker("Gradient End", selection: $gradientEndSelection, supportsOpacity: false)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LColors.textPrimary)
            }
            .settingsCard()
        }
    }

    private var opacitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Opacity")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LColors.textPrimary)

                Spacer()

                Text("\(Int(opacitySelection * 100))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LColors.textSecondary)
            }

            Slider(value: $opacitySelection, in: 0.12...1.0)
                .tint(Color(LColors.accent))
        }
        .settingsCard()
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Preview")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(LColors.textPrimary)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(previewFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
                .frame(height: 140)
                .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 10)
        }
    }

    @ViewBuilder
    private var resetSection: some View {
        if entry.innerPageBackgroundMode != .defaultGlass ||
            !entry.innerPageBackgroundColorHex.isEmpty ||
            !entry.innerPageGradientStartHex.isEmpty ||
            !entry.innerPageGradientEndHex.isEmpty ||
            entry.innerPageOpacity != 0.34 {

            Button {
                resetToDefault()
            } label: {
                Text("Reset to Default")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Preview Fill

    private var previewFill: AnyShapeStyle {
        switch selectedMode {
        case .defaultGlass:
            return AnyShapeStyle(Color.black.opacity(opacitySelection))

        case .solidColor:
            return AnyShapeStyle(solidColorSelection.opacity(opacitySelection))

        case .gradient:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        gradientStartSelection.opacity(opacitySelection),
                        gradientEndSelection.opacity(opacitySelection)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    // MARK: - Actions

    private func loadExistingValues() {
        selectedMode = entry.innerPageBackgroundMode
        opacitySelection = entry.innerPageOpacity

        solidColorSelection = colorFromHex(
            entry.innerPageBackgroundColorHex,
            fallback: .black
        )

        gradientStartSelection = colorFromHex(
            entry.innerPageGradientStartHex,
            fallback: .black
        )

        gradientEndSelection = colorFromHex(
            entry.innerPageGradientEndHex,
            fallback: Color(LColors.accent)
        )
    }

    private func applyChanges() {
        entry.innerPageBackgroundMode = selectedMode
        entry.innerPageOpacity = opacitySelection

        switch selectedMode {
        case .defaultGlass:
            break

        case .solidColor:
            entry.innerPageBackgroundColorHex = hexStringFromColor(UIColor(solidColorSelection))

        case .gradient:
            entry.innerPageGradientStartHex = hexStringFromColor(UIColor(gradientStartSelection))
            entry.innerPageGradientEndHex = hexStringFromColor(UIColor(gradientEndSelection))
        }

        entry.touch()
        dismiss()
    }

    private func resetToDefault() {
        entry.innerPageBackgroundMode = .defaultGlass
        entry.innerPageBackgroundColorHex = ""
        entry.innerPageGradientStartHex = ""
        entry.innerPageGradientEndHex = ""
        entry.innerPageOpacity = 0.34
        entry.touch()
        dismiss()
    }

    // MARK: - Color Helpers

    private func colorFromHex(_ hex: String, fallback: Color) -> Color {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 6,
              let value = Int(cleaned, radix: 16) else {
            return fallback
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        return Color(red: red, green: green, blue: blue)
    }

    private func hexStringFromColor(_ color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        return String(
            format: "%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}

// MARK: - Local Card Modifier

private extension View {
    func settingsCard() -> some View {
        self
            .padding(16)
            .background(Color.black.opacity(0.24))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
    }
}
