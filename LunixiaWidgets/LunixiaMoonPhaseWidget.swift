//
//  LunixiaMoonPhaseWidget.swift
//  Lunixia
//

import WidgetKit
import SwiftUI

// MARK: - MoonPhaseData Extensions (widget-only helpers)

extension MoonPhaseData {
    var phaseIcon: String {
        switch phaseName.lowercased() {
        case "new moon":
            return "moonphase.new.moon"
        case "waxing crescent":
            return "moonphase.waxing.crescent"
        case "first quarter":
            return "moonphase.first.quarter"
        case "waxing gibbous":
            return "moonphase.waxing.gibbous"
        case "full moon":
            return "moonphase.full.moon"
        case "waning gibbous":
            return "moonphase.waning.gibbous"
        case "last quarter", "third quarter":
            return "moonphase.last.quarter"
        case "waning crescent":
            return "moonphase.waning.crescent"
        default:
            return "moonphase.full.moon"
        }
    }

    var zodiacIcon: String {
        switch signName.lowercased() {
        case "aries": return "aries"
        case "taurus": return "taurus"
        case "gemini": return "gemini"
        case "cancer": return "cancer"
        case "leo": return "leo"
        case "virgo": return "virgo"
        case "libra": return "libra"
        case "scorpio": return "scorpio"
        case "sagittarius": return "sagittarius"
        case "capricorn": return "capricorn"
        case "aquarius": return "aquarius"
        case "pisces": return "pisces"
        default: return "aries"
        }
    }

    var illuminationPercentInt: Int {
        Int(illuminationPercent.rounded())
    }
}

// MARK: - Store

enum LunixiaMoonPhaseWidgetStore {
    static let appGroupID = "group.com.asteriasmoons.Lunixia"
    static let snapshotKey = "lunixiaMoonPhaseWidgetSnapshot"

    static func read() -> MoonPhaseData? {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: snapshotKey),
            let decoded = try? JSONDecoder().decode(MoonPhaseData.self, from: data)
        else { return nil }
        return decoded
    }
}

// MARK: - Timeline

struct LunixiaMoonPhaseWidgetEntry: TimelineEntry {
    let date: Date
    let moon: MoonPhaseData
}

struct LunixiaMoonPhaseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LunixiaMoonPhaseWidgetEntry {
        let now = Date()
        return LunixiaMoonPhaseWidgetEntry(
            date: now,
            moon: MoonPhaseCalculator.calculate(for: now)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LunixiaMoonPhaseWidgetEntry) -> Void) {
        let now = Date()
        let moon = LunixiaMoonPhaseWidgetStore.read() ?? MoonPhaseCalculator.calculate(for: now)
        completion(LunixiaMoonPhaseWidgetEntry(date: now, moon: moon))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LunixiaMoonPhaseWidgetEntry>) -> Void) {
        let now = Date()
        var entries: [LunixiaMoonPhaseWidgetEntry] = []

        // Use App Group snapshot for the current entry if available
        let currentMoon = LunixiaMoonPhaseWidgetStore.read() ?? MoonPhaseCalculator.calculate(for: now)
        entries.append(LunixiaMoonPhaseWidgetEntry(date: now, moon: currentMoon))

        // Pre-generate future entries every 4 hours for the next 24 hours
        for hourOffset in stride(from: 4, through: 24, by: 4) {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now)
                ?? now.addingTimeInterval(Double(hourOffset) * 3600)
            entries.append(
                LunixiaMoonPhaseWidgetEntry(
                    date: entryDate,
                    moon: MoonPhaseCalculator.calculate(for: entryDate)
                )
            )
        }

        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 24, to: now)
            ?? now.addingTimeInterval(86400)

        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }
}

// MARK: - Dotted Ring

private struct LunixiaMoonDottedRing: View {
    let moon: MoonPhaseData

    private let dotCount = 40

    private var filledDots: Int {
        let clamped = max(0, min(moon.illuminationPercentInt, 100))
        return Int((Double(clamped) / 100.0 * Double(dotCount)).rounded())
    }

    private var phaseText: String {
        let pieces = moon.phaseName.split(separator: " ")
        if pieces.count == 2 {
            return pieces.joined(separator: "\n")
        } else {
            return moon.phaseName
        }
    }

    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(
                        index < filledDots
                        ? AnyShapeStyle(LGradients.header)
                        : AnyShapeStyle(LColors.textSecondary.opacity(0.32))
                    )
                    .frame(width: 8, height: 8)
                    .offset(y: -52)
                    .rotationEffect(.degrees(Double(index) / Double(dotCount) * 360))
            }

            Text(phaseText)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(LGradients.header)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
                .frame(width: 78)
        }
        .frame(width: 116, height: 116)
    }
}

// MARK: - Info Box

private struct LunixiaMoonInfoBox: View {
    let icon: String?
    let title: String
    let value: String

    var body: some View {
        GlassCard(cornerRadius: 12, padding: 6) {
            VStack(spacing: 2) {
                if let icon {
                    HStack(spacing: 4) {
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(LGradients.header)

                        Text(value)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .fontDesign(.rounded)
                            .foregroundStyle(LGradients.header)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text(value)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .fontDesign(.rounded)
                        .foregroundStyle(LGradients.header)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }

                Text(title)
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .fontDesign(.rounded)
                    .foregroundStyle(LColors.textSecondary.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: 88, height: 46)
    }
}

// MARK: - Medium Widget View

struct LunixiaMoonPhaseMediumWidgetView: View {
    let entry: LunixiaMoonPhaseWidgetEntry

    private var moon: MoonPhaseData {
        entry.moon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                Image(systemName: moon.phaseIcon)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(LGradients.header)
                    .frame(width: 17, height: 17)

                Text("Moon Phase")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .fontDesign(.rounded)
                    .foregroundStyle(LColors.textSecondary)

                Spacer()
            }

            HStack(alignment: .center, spacing: 0) {
                LunixiaMoonDottedRing(moon: moon)
                    .padding(.leading, 16)

                Spacer(minLength: 6)

                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        LunixiaMoonInfoBox(
                            icon: nil,
                            title: "Illumination",
                            value: "\(moon.illuminationPercentInt)%"
                        )

                        LunixiaMoonInfoBox(
                            icon: moon.zodiacIcon,
                            title: "Zodiac",
                            value: moon.signName
                        )
                    }

                    LunixiaMoonInfoBox(
                        icon: nil,
                        title: "Moon Age",
                        value: "Moon Day \(moon.moonDay)"
                    )
                }
                .frame(width: 180, alignment: .trailing)
                .padding(.trailing, 8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .containerBackground(for: .widget) {
            LunixiaBackground()
        }
    }
}

// MARK: - Widget Configuration

struct LunixiaMoonPhaseMediumWidget: Widget {
    let kind = "LunixiaMoonPhaseMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LunixiaMoonPhaseWidgetProvider()) { entry in
            LunixiaMoonPhaseMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Moon Phase")
        .description("Current moon phase, illumination, zodiac sign, and moon day.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
