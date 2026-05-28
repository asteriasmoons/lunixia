//
//  MoodStatsView.swift
//  Lunixia
//

import SwiftUI
import DeviceActivity

struct MoodStatsView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {

                    headerSection

                    overviewSection

                    phoneBehaviorSection

                    deviceActivityReportSection

                    correlationSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Mood Stats")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LGradients.header)

                Text("Explore how your phone behavior may connect with your emotional patterns.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LGradients.header)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Mood Overview")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 14
            ) {
                statCard(
                    icon: "xsmile",
                    title: "Average Mood",
                    value: "—",
                    caption: "Waiting for mood data"
                )

                statCard(
                    icon: "lovejournal",
                    title: "Check-Ins",
                    value: "—",
                    caption: "Logged entries"
                )

                statCard(
                    icon: "sparkle",
                    title: "Best Day",
                    value: "—",
                    caption: "Highest mood average"
                )

                statCard(
                    icon: "timebook",
                    title: "Hardest Day",
                    value: "—",
                    caption: "Lowest mood average"
                )
            }
        }
    }

    // MARK: - Phone Behavior

    private var phoneBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Phone Behavior")

            VStack(spacing: 14) {
                behaviorCard(
                    icon: "lovemobile",
                    title: "Screen Time",
                    value: "—",
                    caption: "Total daily device usage",
                    insight: "Higher screen time may align with lower mood patterns."
                )

                behaviorCard(
                    icon: "socialicon",
                    title: "Social App Usage",
                    value: "—",
                    caption: "Selected social apps/categories",
                    insight: "Extended social usage may correlate with overwhelm or comparison fatigue."
                )

                behaviorCard(
                    icon: "moonzs",
                    title: "Nighttime Phone Use",
                    value: "—",
                    caption: "Late-night device activity",
                    insight: "Night usage may connect with lower-energy moods the next day."
                )

                behaviorCard(
                    icon: "tapicon",
                    title: "Pickups / Unlocks",
                    value: "—",
                    caption: "Checking behavior",
                    insight: "Frequent pickups may correlate with anxious or restless moods."
                )

                behaviorCard(
                    icon: "bellfill",
                    title: "Notifications",
                    value: "—",
                    caption: "Interruption volume",
                    insight: "Heavy notification days may correlate with overstimulation."
                )
            }
        }
    }

    // MARK: - Correlations

    private var correlationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Pattern Insights")

            insightCard(
                icon: "sparklesearch",
                title: "No patterns yet",
                text: "Once Lunixia has mood logs and phone behavior data for multiple days, this page can compare them and surface gentle correlations."
            )

            insightCard(
                icon: "lockwavy",
                title: "Planned data sources",
                text: "This page is designed for Device Activity data only. No app blocking, no limits, and no ManagedSettings enforcement."
            )
        }
    }

    // MARK: - Components

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .black, design: .rounded))
            .foregroundStyle(LGradients.header)
    }

    private func statCard(
        icon: String,
        title: String,
        value: String,
        caption: String
    ) -> some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(LGradients.header)

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textPrimary)

                    Text(caption)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func behaviorCard(
        icon: String,
        title: String,
        value: String,
        caption: String,
        insight: String
    ) -> some View {
        GlassCard(padding: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        Text(value)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                    }

                    Text(caption)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Text(insight)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textPrimary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func insightCard(
        icon: String,
        title: String,
        text: String
    ) -> some View {
        GlassCard(padding: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LGradients.header)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(text)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
    }

    // MARK: - Device Activity Report

    private var deviceActivityReportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Live Device Activity")

            GlassCard(padding: 16) {
                DeviceActivityReport(.lunixiaMoodStats, filter: todayDeviceActivityFilter)
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
            }
        }
    }

    private var todayDeviceActivityFilter: DeviceActivityFilter {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .day, for: Date()) ?? DateInterval(
            start: calendar.startOfDay(for: Date()),
            duration: 86_400
        )

        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
    }
}
