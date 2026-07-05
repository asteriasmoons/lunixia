//
//  LunixiaMoodWidget.swift
//  Lunixia
//

import WidgetKit
import SwiftUI

// MARK: - Snapshot

struct LunixiaMoodWidgetSnapshot: Codable {
    var wellnessPercent: Int
    var wellnessLabel: String
    var streak: Int
    var totalLogs: Int
    var sevenDayLogCount: Int
    var positivePct: Int
    var neutralPct: Int
    var negativePct: Int
    var topEmotion: String
    var topActivity: String
    var lastUpdated: Date
}

// MARK: - Store

enum LunixiaMoodWidgetStore {
    static let appGroupID  = "group.com.asteriasmoons.Lunixia"
    static let snapshotKey = "lunixiaMoodWidgetSnapshot"

    static func read() -> LunixiaMoodWidgetSnapshot {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data     = defaults.data(forKey: snapshotKey),
            let decoded  = try? JSONDecoder().decode(LunixiaMoodWidgetSnapshot.self, from: data)
        else { return placeholder }
        return decoded
    }

    static var placeholder: LunixiaMoodWidgetSnapshot {
        LunixiaMoodWidgetSnapshot(
            wellnessPercent: 0,
            wellnessLabel: "Nothing Logged Yet",
            streak: 0,
            totalLogs: 0,
            sevenDayLogCount: 0,
            positivePct: 0,
            neutralPct: 0,
            negativePct: 0,
            topEmotion: "",
            topActivity: "",
            lastUpdated: Date()
        )
    }
}

// MARK: - Timeline Entry & Provider

struct LunixiaMoodWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: LunixiaMoodWidgetSnapshot
}

struct LunixiaMoodWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LunixiaMoodWidgetEntry {
        LunixiaMoodWidgetEntry(date: Date(), snapshot: LunixiaMoodWidgetStore.placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (LunixiaMoodWidgetEntry) -> Void) {
        completion(LunixiaMoodWidgetEntry(date: Date(), snapshot: LunixiaMoodWidgetStore.read()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LunixiaMoodWidgetEntry>) -> Void) {
        let entry = LunixiaMoodWidgetEntry(date: Date(), snapshot: LunixiaMoodWidgetStore.read())
        let next  = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Emotion Range Bar

private struct EmotionRangeBar: View {
    let positivePct: Int
    let neutralPct:  Int
    let negativePct: Int
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 3) {
                if positivePct > 0 {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(lunixiaHex: "#9B6FF7"), Color(lunixiaHex: "#7d19f7")],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(geo.size.width * CGFloat(positivePct) / 100, 4))
                }
                if neutralPct > 0 {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(lunixiaHex: "#03dbfc"), Color(lunixiaHex: "#00b8d9")],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(geo.size.width * CGFloat(neutralPct) / 100, 4))
                }
                if negativePct > 0 {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(lunixiaHex: "#e019d4"), Color(lunixiaHex: "#b8009e")],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(geo.size.width * CGFloat(negativePct) / 100, 4))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        }
        .frame(height: height)
    }
}

// MARK: - Legend Dot

private struct LegendDot: View {
    let color: Color
    let label: String
    let value: Int

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(value)% \(label)")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.textSecondary.opacity(0.6))
        }
    }
}

// MARK: - Medium Widget View

struct LunixiaMoodMediumWidgetView: View {
    let entry: LunixiaMoodWidgetEntry
    private var s: LunixiaMoodWidgetSnapshot { entry.snapshot }
    private var hasEmotionData: Bool { s.positivePct > 0 || s.neutralPct > 0 || s.negativePct > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("7-Day Snapshot")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                Spacer()
                Text(s.sevenDayLogCount == 0 ? "No Data" : "\(s.sevenDayLogCount) Logs")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.45))
            }

            if hasEmotionData {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Emotional Range")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.5))

                    EmotionRangeBar(positivePct: s.positivePct, neutralPct: s.neutralPct, negativePct: s.negativePct, height: 8)

                    HStack(spacing: 10) {
                        LegendDot(color: Color(lunixiaHex: "#9B6FF7"), label: "Positive", value: s.positivePct)
                        LegendDot(color: Color(lunixiaHex: "#03dbfc"), label: "Neutral",  value: s.neutralPct)
                        LegendDot(color: Color(lunixiaHex: "#e019d4"), label: "Negative", value: s.negativePct)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(LColors.glassSurface)
                    .frame(height: 8)
                Text("Log Some Moods to See Your Range")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.4))
            }

            Rectangle()
                .fill(LColors.glassBorder)
                .frame(height: 1)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Most Felt")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.5))
                    Text(s.topEmotion.isEmpty ? "—" : s.topEmotion.capitalized)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                        .lineLimit(1)
                }

                Spacer()

                Rectangle()
                    .fill(LColors.glassBorder)
                    .frame(width: 1, height: 30)

                Spacer()

                VStack(alignment: .leading, spacing: 3) {
                    Text("Top Activity")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.5))
                    Text(s.topActivity.isEmpty ? "—" : s.topActivity.capitalized)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .containerBackground(for: .widget) {
            LunixiaBackground()
        }
    }
}

// MARK: - Large Widget View

struct LunixiaMoodLargeWidgetView: View {
    let entry: LunixiaMoodWidgetEntry
    private var s: LunixiaMoodWidgetSnapshot { entry.snapshot }
    private var hasEmotionData: Bool { s.positivePct > 0 || s.neutralPct > 0 || s.negativePct > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Stats row
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(s.wellnessPercent)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("%")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                            .offset(y: -1)
                    }
                    Text(s.wellnessLabel)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                Rectangle()
                    .fill(LColors.glassBorder)
                    .frame(width: 1, height: 38)

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(s.streak)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("Day Streak")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .offset(y: -1)
                    }
                    Text(s.streak == 0 ? "Log Today to Start" : s.streak == 1 ? "Keep It Going" : "On a Roll")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                Rectangle()
                    .fill(LColors.glassBorder)
                    .frame(width: 1, height: 38)

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(s.totalLogs)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("Logs")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .offset(y: -1)
                    }
                    Text("All Time")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.6))
                }
            }

            Rectangle()
                .fill(LColors.glassBorder)
                .frame(height: 1)

            // 7-day snapshot
            VStack(alignment: .leading, spacing: 14) {

                HStack {
                    Text("7-Day Snapshot")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                    Spacer()
                    Text(s.sevenDayLogCount == 0 ? "No Data" : "\(s.sevenDayLogCount) Logs")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.45))
                }

                if hasEmotionData {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Emotional Range")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.5))

                        EmotionRangeBar(positivePct: s.positivePct, neutralPct: s.neutralPct, negativePct: s.negativePct, height: 10)

                        HStack(spacing: 12) {
                            LegendDot(color: Color(lunixiaHex: "#9B6FF7"), label: "Positive", value: s.positivePct)
                            LegendDot(color: Color(lunixiaHex: "#03dbfc"), label: "Neutral",  value: s.neutralPct)
                            LegendDot(color: Color(lunixiaHex: "#e019d4"), label: "Negative", value: s.negativePct)
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(LColors.glassSurface)
                        .frame(height: 10)
                    Text("Log Some Moods to See Your Range")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.4))
                }

                Rectangle()
                    .fill(LColors.glassBorder)
                    .frame(height: 1)

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Most Felt")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.5))
                        Text(s.topEmotion.isEmpty ? "—" : s.topEmotion.capitalized)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                            .lineLimit(1)
                    }

                    Spacer()

                    Rectangle()
                        .fill(LColors.glassBorder)
                        .frame(width: 1, height: 30)

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top Activity")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.5))
                        Text(s.topActivity.isEmpty ? "—" : s.topActivity.capitalized)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .containerBackground(for: .widget) {
            LunixiaBackground()
        }
    }
}

// MARK: - Widget Configurations

struct LunixiaMoodMediumWidget: Widget {
    let kind = "LunixiaMoodMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LunixiaMoodWidgetProvider()) { entry in
            LunixiaMoodMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Mood — 7-Day Snapshot")
        .description("Your emotional range and top mood over the last 7 days.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct LunixiaMoodLargeWidget: Widget {
    let kind = "LunixiaMoodLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LunixiaMoodWidgetProvider()) { entry in
            LunixiaMoodLargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Mood — Full Overview")
        .description("Wellness score, streak, all-time logs, and your 7-day emotional snapshot.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
