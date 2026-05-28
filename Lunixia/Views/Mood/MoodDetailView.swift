//
//  MoodDetailView.swift
//  Lunixia
//

import SwiftUI

struct MoodDetailView: View {
    let entry: MoodEntry
    @Environment(\.dismiss) private var dismiss

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

                    // MARK: Emotions card
                    if !entry.resolvedEmotions.isEmpty {
                        GlassCard(padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionLabel(icon: "xsmile", isCustom: true, text: "emotions")

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
                                sectionLabel(icon: "sparkle", isCustom: true, text: "activities")

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
                            sectionLabel(icon: "balancewavy", isCustom: true, text: "check-in")

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                attachmentTile(icon: "sun", isCustom: true, label: "Weather",
                                    value: entry.weatherNote.isEmpty ? "--" : entry.weatherNote)
                                attachmentTile(icon: "moonzs", isCustom: true, label: "Sleep",
                                    value: entry.sleepHours == 0 ? "--" : String(format: "%.1fh", entry.sleepHours))
                                attachmentTile(icon: "dumbbell", isCustom: true, label: "Exercise",
                                    value: entry.exerciseMinutes == 0 ? "--" : "\(entry.exerciseMinutes)m")
                                attachmentTile(icon: "shoe", isCustom: true, label: "Steps",
                                    value: entry.steps == 0 ? "--" : "\(entry.steps)")
                                attachmentTile(icon: "sunflower", isCustom: true, label: "Meditation",
                                    value: entry.meditationMinutes == 0 ? "--" : "\(entry.meditationMinutes)m")
                                attachmentTile(icon: "arrow.triangle.2.circlepath", isCustom: false, label: "Cycle",
                                    value: entry.cycleNote.isEmpty ? "--" : entry.cycleNote)
                                attachmentTile(icon: "bottle", isCustom: true, label: "Water",
                                    value: entry.waterOz == 0 ? "--" : String(format: "%.0foz", entry.waterOz))
                                attachmentTile(icon: "glass", isCustom: true, label: "Caffeine",
                                    value: entry.caffeineNote.isEmpty ? "--" : entry.caffeineNote)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: Note card
                    if !entry.note.isEmpty {
                        GlassCard(padding: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                sectionLabel(icon: "writenote", isCustom: true, text: "note")
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
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LGradients.header)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(LGradients.header)
            }
            Text(text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
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
