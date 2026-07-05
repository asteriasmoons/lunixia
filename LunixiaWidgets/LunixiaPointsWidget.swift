//
//  LunixiaPointsWidget.swift
//  Lunixia
//


import WidgetKit
import SwiftUI

private let pointsPink = Color(red: 1.0, green: 0.35, blue: 0.65)
private let pointsPinkSoft = Color(red: 1.0, green: 0.35, blue: 0.65).opacity(0.18)
private let pointsPinkGrad = LinearGradient(
    colors: [Color(red: 1.0, green: 0.4, blue: 0.7), Color(red: 1.0, green: 0.2, blue: 0.5)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Snapshot

struct LunixiaPointsWidgetSnapshot: Codable {
    var currentPoints: Int
    var currentLevel: Int
    var progressInCurrentLevel: Int
    var pointsNeededToNextLevel: Int
    var pointsToday: Int
    var pointsPerLevel: Int
    var lastUpdated: Date
}

// MARK: - Entry

struct LunixiaPointsWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: LunixiaPointsWidgetSnapshot
}

// MARK: - Provider

struct LunixiaPointsWidgetProvider: TimelineProvider {
    private let appGroupID = "group.com.asteriasmoons.Lunixia"
    private let snapshotKey = "lunixia.points.widget.snapshot"

    func placeholder(in context: Context) -> LunixiaPointsWidgetEntry {
        LunixiaPointsWidgetEntry(
            date: Date(),
            snapshot: fallbackSnapshot()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LunixiaPointsWidgetEntry) -> Void) {
        completion(
            LunixiaPointsWidgetEntry(
                date: Date(),
                snapshot: loadSnapshot()
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LunixiaPointsWidgetEntry>) -> Void) {
        let entry = LunixiaPointsWidgetEntry(
            date: Date(),
            snapshot: loadSnapshot()
        )

        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)

        completion(
            Timeline(
                entries: [entry],
                policy: .after(refreshDate)
            )
        )
    }

    private func loadSnapshot() -> LunixiaPointsWidgetSnapshot {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard

        guard
            let data = defaults.data(forKey: snapshotKey),
            let snapshot = try? JSONDecoder().decode(LunixiaPointsWidgetSnapshot.self, from: data)
        else {
            return fallbackSnapshot()
        }

        return snapshot
    }

    private func fallbackSnapshot() -> LunixiaPointsWidgetSnapshot {
        LunixiaPointsWidgetSnapshot(
            currentPoints: 0,
            currentLevel: 0,
            progressInCurrentLevel: 0,
            pointsNeededToNextLevel: 100,
            pointsToday: 0,
            pointsPerLevel: 100,
            lastUpdated: Date()
        )
    }
}

// MARK: - Medium Widget View

struct LunixiaPointsMediumWidgetView: View {
    let entry: LunixiaPointsWidgetEntry
    private var s: LunixiaPointsWidgetSnapshot { entry.snapshot }

    private var progress: Double {
        guard s.pointsPerLevel > 0 else { return 0 }
        return min(max(Double(s.progressInCurrentLevel) / Double(s.pointsPerLevel), 0), 1)
    }

    private var progressPercentText: String {
        "\(Int((progress * 100).rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image("heartwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(pointsPinkGrad)

                Text("Self-Care Points")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(pointsPinkGrad)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)

            HStack(alignment: .center, spacing: 14) {
                pointsRing

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 6),
                        GridItem(.flexible(), spacing: 6)
                    ],
                    spacing: 6
                ) {
                    PointsWidgetStatBox(label: "Current", value: "\(s.currentPoints)", compact: true)
                    PointsWidgetStatBox(label: "Level", value: "\(s.currentLevel)", compact: true)
                    PointsWidgetStatBox(label: "Today", value: "\(s.pointsToday)", compact: true)
                    PointsWidgetStatBox(label: "To Level", value: "\(s.pointsNeededToNextLevel)", compact: true)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.leading, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 14)
        .padding(.top, 13)
        .padding(.bottom, 12)
        .containerBackground(for: .widget) {
            LunixiaBackground()
        }
    }
    
    private var pointsRing: some View {
        DottedHeartPointsRing(
            progress: progress,
            size: 104,
            dotCount: 34,
            dotSize: 10
        )
    }
}

// MARK: - Large Widget View

struct LunixiaPointsLargeWidgetView: View {
    let entry: LunixiaPointsWidgetEntry
    private var s: LunixiaPointsWidgetSnapshot { entry.snapshot }

    private var progress: Double {
        guard s.pointsPerLevel > 0 else { return 0 }
        return min(max(Double(s.progressInCurrentLevel) / Double(s.pointsPerLevel), 0), 1)
    }

    private var progressPercentText: String {
        "\(Int((progress * 100).rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image("heartwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(pointsPinkGrad)

                Text("Self-Care Points")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(pointsPinkGrad)
                    .lineLimit(1)

                Spacer()
            }

            HStack {
                Spacer()
                pointsRing
                Spacer()
            }
            .frame(height: 150)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                PointsWidgetStatBox(label: "Current", value: "\(s.currentPoints)", compact: false)
                PointsWidgetStatBox(label: "Level", value: "\(s.currentLevel)", compact: false)
                PointsWidgetStatBox(label: "Today", value: "\(s.pointsToday)", compact: false)
                PointsWidgetStatBox(label: "To Level", value: "\(s.pointsNeededToNextLevel)", compact: false)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .containerBackground(for: .widget) {
            LunixiaBackground()
        }
    }
    
    private var pointsRing: some View {
        DottedHeartPointsRing(
            progress: progress,
            size: 136,
            dotCount: 42,
            dotSize: 12
        )
    }
}

// MARK: - Points Stat Box

private struct PointsWidgetStatBox: View {
    let label: String
    let value: String
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            Text(label.uppercased())
                .font(.system(size: compact ? 7.2 : 9, weight: .black, design: .rounded))
                .foregroundStyle(pointsPink.opacity(0.72))
                .kerning(0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(value)
                .font(.system(size: compact ? 15 : 20, weight: .black, design: .rounded))
                .foregroundStyle(pointsPink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 36 : 58, alignment: .leading)
        .padding(.horizontal, compact ? 7 : 12)
        .padding(.vertical, compact ? 5 : 10)
        .background(
            RoundedRectangle(cornerRadius: compact ? 10 : 16, style: .continuous)
                .fill(pointsPink.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 10 : 16, style: .continuous)
                        .strokeBorder(pointsPink.opacity(0.25), lineWidth: 0.75)
                )
        )
    }
}

// MARK: - Dotted Points Ring

private struct DottedHeartPointsRing: View {
    let progress: Double
    let size: CGFloat
    let dotCount: Int
    let dotSize: CGFloat

    private var activeDots: Int {
        Int((min(max(progress, 0), 1) * Double(dotCount)).rounded())
    }

    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                let isActive = index < activeDots
                let point = heartPoint(index: index)

                Circle()
                    .fill(isActive ? AnyShapeStyle(pointsPinkGrad) : AnyShapeStyle(pointsPinkSoft))
                    .frame(width: dotSize, height: dotSize)
                    .shadow(color: isActive ? pointsPink.opacity(0.32) : .clear, radius: 4, y: 1)
                    .position(x: point.x, y: point.y)
            }
        }
        .frame(width: size, height: size)
    }

    private func heartPoint(index: Int) -> CGPoint {
        let segmentProgress = Double(index) / Double(dotCount)
        let scaled = segmentProgress * 6.0
        let segment = min(Int(scaled), 5)
        let t = scaled - Double(segment)

        let p: CGPoint

        switch segment {
        case 0:
            p = cubicPoint(
                t: t,
                p0: CGPoint(x: 0.50, y: 0.31),
                p1: CGPoint(x: 0.57, y: 0.15),
                p2: CGPoint(x: 0.82, y: 0.13),
                p3: CGPoint(x: 0.87, y: 0.36)
            )
        case 1:
            p = cubicPoint(
                t: t,
                p0: CGPoint(x: 0.87, y: 0.36),
                p1: CGPoint(x: 0.91, y: 0.53),
                p2: CGPoint(x: 0.77, y: 0.67),
                p3: CGPoint(x: 0.63, y: 0.76)
            )
        case 2:
            p = cubicPoint(
                t: t,
                p0: CGPoint(x: 0.63, y: 0.76),
                p1: CGPoint(x: 0.58, y: 0.80),
                p2: CGPoint(x: 0.53, y: 0.84),
                p3: CGPoint(x: 0.50, y: 0.86)
            )
        case 3:
            p = cubicPoint(
                t: t,
                p0: CGPoint(x: 0.50, y: 0.86),
                p1: CGPoint(x: 0.47, y: 0.84),
                p2: CGPoint(x: 0.42, y: 0.80),
                p3: CGPoint(x: 0.37, y: 0.76)
            )
        case 4:
            p = cubicPoint(
                t: t,
                p0: CGPoint(x: 0.37, y: 0.76),
                p1: CGPoint(x: 0.23, y: 0.67),
                p2: CGPoint(x: 0.09, y: 0.53),
                p3: CGPoint(x: 0.13, y: 0.36)
            )
        default:
            p = cubicPoint(
                t: t,
                p0: CGPoint(x: 0.13, y: 0.36),
                p1: CGPoint(x: 0.18, y: 0.13),
                p2: CGPoint(x: 0.43, y: 0.15),
                p3: CGPoint(x: 0.50, y: 0.31)
            )
        }

        return CGPoint(x: p.x * size, y: p.y * size)
    }

    private func cubicPoint(t: Double, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let oneMinusT = 1.0 - t
        let x =
            pow(oneMinusT, 3.0) * p0.x +
            3.0 * pow(oneMinusT, 2.0) * t * p1.x +
            3.0 * oneMinusT * pow(t, 2.0) * p2.x +
            pow(t, 3.0) * p3.x

        let y =
            pow(oneMinusT, 3.0) * p0.y +
            3.0 * pow(oneMinusT, 2.0) * t * p1.y +
            3.0 * oneMinusT * pow(t, 2.0) * p2.y +
            pow(t, 3.0) * p3.y

        return CGPoint(x: x, y: y)
    }
}


// MARK: - Widgets

struct LunixiaPointsMediumWidget: Widget {
    let kind = "LunixiaPointsMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LunixiaPointsWidgetProvider()) { entry in
            LunixiaPointsMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Self-Care Points")
        .description("Shows your current points, level, and level progress.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct LunixiaPointsLargeWidget: Widget {
    let kind = "LunixiaPointsLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LunixiaPointsWidgetProvider()) { entry in
            LunixiaPointsLargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Self-Care Points")
        .description("Shows your current points, level, and progress toward the next level.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
