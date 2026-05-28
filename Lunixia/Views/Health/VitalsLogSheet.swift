//
//  VitalsLogSheet.swift
//  Lunixia
//

import SwiftUI
import SwiftData

struct VitalsLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var storeManager: LunixiaStoreManager

    @State private var bloodOxygen: String = ""
    @State private var systolic: String = ""
    @State private var diastolic: String = ""
    @State private var bpm: String = ""
    @State private var bodyTemp: String = ""
    @State private var weight: String = ""

    let todayVitalsEntryCount: Int
    let onPremiumRequired: () -> Void
    let onSave: (VitalsEntry) -> Void

    private var isPremium: Bool {
        storeManager.isPremium
    }

    private var isLockedByLimit: Bool {
        !LunixiaLimitsManager.canCreateCompleteVitalsEntry(
            todayCount: todayVitalsEntryCount,
            isPremium: isPremium
        )
    }

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image("xmarkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(LGradients.header)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("Log Vitals")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    Spacer()
                    Color.clear.frame(width: 22, height: 22)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        vitalsField(label: "Blood Oxygen", unit: "%", placeholder: "e.g. 98", text: $bloodOxygen, keyboardType: .decimalPad)
                        vitalsField(label: "Systolic", unit: "mmHg", placeholder: "e.g. 120", text: $systolic, keyboardType: .numberPad)
                        vitalsField(label: "Diastolic", unit: "mmHg", placeholder: "e.g. 80", text: $diastolic, keyboardType: .numberPad)
                        vitalsField(label: "BPM", unit: "bpm", placeholder: "e.g. 72", text: $bpm, keyboardType: .numberPad)
                        vitalsField(label: "Body Temp", unit: "°F", placeholder: "e.g. 98.6", text: $bodyTemp, keyboardType: .decimalPad)
                        vitalsField(label: "Weight", unit: "lbs", placeholder: "e.g. 145", text: $weight, keyboardType: .decimalPad)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                ZStack {
                    Button { save() } label: {
                        HStack(spacing: 8) {
                            Image("checkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                            Text("Save Vitals")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                                .fill(LColors.accentGradient)
                                .shadow(color: LColors.gradientPurple.opacity(0.35), radius: 12, y: 6)
                        )
                        .opacity(isLockedByLimit ? 0.4 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLockedByLimit)

                    if isLockedByLimit {
                        Button {
                            onPremiumRequired()
                        } label: {
                            LunixiaPremiumBlurOverlay(cornerRadius: LSpacing.buttonRadius)
                                .frame(height: 56)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
    }

    @ViewBuilder
    private func vitalsField(label: String, unit: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            HStack {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)

                Text(unit)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LColors.glassSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [LColors.gradientBlue, LColors.gradientPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.35
                            )
                    )
            )
        }
    }

    private func save() {
        guard !isLockedByLimit else {
            onPremiumRequired()
            return
        }

        let entry = VitalsEntry(
            bloodOxygen: Double(bloodOxygen) ?? 0,
            bpm: Double(bpm) ?? 0,
            systolic: Double(systolic) ?? 0,
            diastolic: Double(diastolic) ?? 0,
            bodyTemp: Double(bodyTemp) ?? 0,
            weight: Double(weight) ?? 0
        )
        onSave(entry)
        _ = try? LunixiaPointsManager.awardVitalsLog(
            in: modelContext,
            id: entry.id.uuidString,
            at: entry.timestamp
        )
        dismiss()
    }
}

