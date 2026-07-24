//
//  MoodDetailView.swift
//  Lunixia
//

import SwiftUI

struct MoodDetailView: View {
    let entry: MoodEntry
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var showInsights = false
    @State private var showHistory = false

#if canImport(UIKit)
    private var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
#else
    private var isIPad: Bool { false }
#endif

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mood Log")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(LGradients.header)
                            Text(entry.timestamp.formatted(date: .complete, time: .shortened))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(LGradients.header)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // MARK: Action Buttons
                    HStack(spacing: 12) {
                        Button { showInsights = true } label: {
                            HStack(spacing: 6) {
                                Image("cloudmind")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15)
                                Text("Analyze")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(LGradients.blue.opacity(0.22))
                            )
                            .overlay(
                                Capsule().strokeBorder(LGradients.blue.opacity(0.55), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Button { showHistory = true } label: {
                            HStack(spacing: 6) {
                                Image("clockfill")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15)
                                Text("History")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(LColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // MARK: Emotions card
                    if !entry.resolvedEmotions.isEmpty {
                        GlassCard(padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionLabel(icon: "xsmile", isCustom: true, text: "Inner Weather")

                                FlowLayout(spacing: 7) {
                                    ForEach(entry.resolvedEmotions) { emotion in
                                        let colors = emotion.category.bubbleColors
                                        Text(emotion.name)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 13)
                                            .padding(.vertical, 7)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                Color(lunixiaHex: colors.Color1).opacity(0.85),
                                                                Color(lunixiaHex: colors.Color2).opacity(0.7)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // MARK: Activities card
                    if !entry.resolvedActivities.isEmpty {
                        GlassCard(padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionLabel(icon: "sparkle", isCustom: true, text: "Activities")

                                FlowLayout(spacing: 7) {
                                    ForEach(entry.resolvedActivities) { activity in
                                        HStack(spacing: 5) {
                                            if activity.isCustomAsset {
                                                Image(activity.icon)
                                                    .renderingMode(.template)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 12, height: 12)
                                            } else {
                                                Image(systemName: activity.icon)
                                                    .font(.system(size: 12, weight: .semibold))
                                            }
                                            Text(activity.name)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule()
                                                .fill(LColors.accentGradient.opacity(0.8))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // MARK: Attachments card
                    GlassCard(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            sectionLabel(icon: "balancewavy", isCustom: true, text: "Lifestyle")

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                attachmentTile(icon: "moonzs", isCustom: true, label: "Sleep",
                                    value: entry.sleepHours == 0 ? "--" : String(format: "%.1fh", entry.sleepHours))
                                attachmentTile(icon: "dumbbell", isCustom: true, label: "Exercise",
                                    value: entry.exerciseMinutes == 0 ? "--" : "\(entry.exerciseMinutes)m")
                                attachmentTile(icon: "shoe", isCustom: true, label: "Steps",
                                    value: entry.steps == 0 ? "--" : "\(entry.steps)")
                                attachmentTile(icon: "sunflower", isCustom: true, label: "Mindfulness",
                                    value: entry.meditationMinutes == 0 ? "--" : "\(entry.meditationMinutes)m")
                                attachmentTile(icon: "bottle", isCustom: true, label: "Water",
                                    value: entry.waterOz == 0 ? "--" : String(format: "%.0foz", entry.waterOz))
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: Note card
                    if !entry.note.isEmpty {
                        GlassCard(padding: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                sectionLabel(icon: "writenote", isCustom: true, text: "Note")
                                Text(entry.note)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundStyle(LColors.textPrimary.opacity(0.88))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 60)
                }
            }
        }
        // Insights — sheet on iPhone, fullScreenCover on iPad
        .sheet(isPresented: Binding(
            get: { !isIPad && showInsights },
            set: { if !$0 { showInsights = false } }
        )) {
            MoodInsightsView(entry: entry, userId: appState.currentAppleUserId ?? "")
        }
        .fullScreenCover(isPresented: Binding(
            get: { isIPad && showInsights },
            set: { if !$0 { showInsights = false } }
        )) {
            MoodInsightsView(entry: entry, userId: appState.currentAppleUserId ?? "")
        }
        // History — sheet on iPhone, fullScreenCover on iPad
        .sheet(isPresented: Binding(
            get: { !isIPad && showHistory },
            set: { if !$0 { showHistory = false } }
        )) {
            MoodInsightsHistoryView(
                userId: appState.currentAppleUserId ?? "",
                moodEntryId: nil
            )
        }
        .fullScreenCover(isPresented: Binding(
            get: { isIPad && showHistory },
            set: { if !$0 { showHistory = false } }
        )) {
            MoodInsightsHistoryView(
                userId: appState.currentAppleUserId ?? "",
                moodEntryId: nil
            )
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func sectionLabel(icon: String, isCustom: Bool, text: String) -> some View {
        HStack(spacing: 7) {
            if isCustom {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(LGradients.header)
            }
            Text(text)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
    }

    @ViewBuilder
    private func attachmentTile(icon: String, isCustom: Bool, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LColors.glassSurface2)
                    .frame(width: 42, height: 42)

                if isCustom {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 19, height: 19)
                        .foregroundStyle(LGradients.header)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(LGradients.header)
                }
            }

            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(value == "--" ? LColors.textSecondary.opacity(0.35) : LColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
