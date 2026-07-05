//
//  MoodStatsReportView.swift
//  Lunixia
//

import SwiftUI

struct MoodStatsReportView: View {

    let model: MoodStatsReportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: - Behavior Cards
            VStack(spacing: 10) {
                behaviorRow(
                    title: "Screen Time",
                    value: formattedScreenTime,
                    caption: "Total daily device usage",
                    icon: "device"
                )
                behaviorRow(
                    title: "Social App Usage",
                    value: formattedMinutes(model.socialAppMinutes),
                    caption: "Social categories",
                    icon: "socialicon"
                )
                behaviorRow(
                    title: "Nighttime Phone Use",
                    value: formattedMinutes(model.nighttimePhoneMinutes),
                    caption: "Activity after 9 PM",
                    icon: "moonzs"
                )
                behaviorRow(
                    title: "Pickups / Unlocks",
                    value: "\(model.pickupCount)",
                    caption: "Checking behavior",
                    icon: "tapicon"
                )
                behaviorRow(
                    title: "Notifications",
                    value: "\(model.notificationCount)",
                    caption: "Interruption volume",
                    icon: "bellfill"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Components

    private var formattedScreenTime: String {
        formattedMinutes(model.totalScreenTimeMinutes)
    }

    private func formattedMinutes(_ value: Double) -> String {
        let minutes = Int(value.rounded())
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 { return "\(hours)h \(remaining)m" }
        return "\(remaining)m"
    }

    private func behaviorRow(
        title: String,
        value: String,
        caption: String,
        icon: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.02, green: 0.86, blue: 0.99),
                                        Color(red: 0.61, green: 0.44, blue: 0.97)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )

                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.02, green: 0.86, blue: 0.99), Color(red: 0.61, green: 0.44, blue: 0.97)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(value)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.02, green: 0.86, blue: 0.99), Color(red: 0.61, green: 0.44, blue: 0.97)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
                Text(caption)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
    }
}
