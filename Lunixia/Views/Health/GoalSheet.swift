//
//  GoalSheet.swift
//  Lunixia
//

import SwiftUI

struct GoalSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var goals: HealthGoals
    let onSave: () -> Void

    @State private var waterInput: String = ""
    @State private var stepsInput: String = ""

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
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
                    Text("Set Goals")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    Spacer()
                    Color.clear.frame(width: 22, height: 22)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)

                VStack(spacing: 14) {
                    goalField(label: "Daily Water Goal", unit: "oz", text: $waterInput, placeholder: "\(Int(goals.dailyWaterOz))")
                    goalField(label: "Daily Steps Goal", unit: "steps", text: $stepsInput, placeholder: "\(goals.dailySteps)")
                }
                .padding(.horizontal, 20)

                Spacer()

                Button {
                    if let oz = Double(waterInput), oz > 0 { goals.dailyWaterOz = oz }
                    if let steps = Int(stepsInput), steps > 0 { goals.dailySteps = steps }
                    onSave()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image("checkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("Save Goals")
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
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
    }

    @ViewBuilder
    private func goalField(label: String, unit: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            HStack {
                TextField(placeholder, text: text)
                    .keyboardType(.numberPad)
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
}
