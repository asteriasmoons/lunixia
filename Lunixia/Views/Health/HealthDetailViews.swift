//
//  VitalsDetailView.swift
//  Lunixia
//

import SwiftUI
import SwiftData

struct VitalsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var storeManager: LunixiaStoreManager
    @Query(sort: \VitalsEntry.timestamp, order: .reverse) private var allEntries: [VitalsEntry]

    let entry: VitalsEntry
    @State private var visibleCount = 4
    private let pageSize = 4

    private var isPremium: Bool {
        storeManager.isPremium
    }

    private var allFiltered: [VitalsEntry] {
        if isPremium { return allEntries }
        let cutoff = LunixiaLimitsManager.historyCutoffDate(
            days: LunixiaLimitsManager.vitalsHistoryDaysLimit(isPremium: false)
        )
        return allEntries.filter { $0.timestamp >= cutoff }
    }

    private var visibleEntries: [VitalsEntry] {
        Array(allFiltered.prefix(visibleCount))
    }

    private var totalCount: Int { allFiltered.count }

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Vitals History")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
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
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(visibleEntries) { e in
                            GlassCard(padding: 16) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(e.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)

                                    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                                        GridRow {
                                            vitalsTile(label: "SpO2", value: e.bloodOxygen == 0 ? "--" : "\(Int(e.bloodOxygen))%")
                                            vitalsTile(label: "Systolic", value: e.systolic == 0 ? "--" : "\(Int(e.systolic))")
                                            vitalsTile(label: "Diastolic", value: e.diastolic == 0 ? "--" : "\(Int(e.diastolic))")
                                        }

                                        GridRow {
                                            vitalsTile(label: "BPM", value: e.bpm == 0 ? "--" : "\(Int(e.bpm)) bpm")
                                            vitalsTile(label: "Temp", value: e.bodyTemp == 0 ? "--" : String(format: "%.1f°F", e.bodyTemp))
                                            vitalsTile(label: "Weight", value: e.weight == 0 ? "--" : String(format: "%.1f lbs", e.weight))
                                        }
                                    }
                                }
                            }
                        }

                        if totalCount > pageSize {
                            VStack(spacing: 10) {
                                if visibleCount < totalCount {
                                    Button {
                                        withAnimation { visibleCount = min(visibleCount + pageSize, totalCount) }
                                    } label: {
                                        Text("Load More")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 9)
                                            .background(LColors.accentGradient, in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }

                                if visibleCount > pageSize {
                                    Button {
                                        withAnimation { visibleCount = pageSize }
                                    } label: {
                                        Text("See Less")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(LColors.textSecondary)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 9)
                                            .background(
                                                Capsule().fill(LColors.glassSurface)
                                                    .overlay(Capsule().strokeBorder(LColors.glassBorder, lineWidth: 1))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    @ViewBuilder
    private func vitalsTile(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(value == "--" ? LColors.textSecondary.opacity(0.35) : LColors.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LColors.glassSurface)
        )
    }
}

// MARK: - Exercise Detail View

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeManager: LunixiaStoreManager
    @Query(sort: \ExerciseEntry.timestamp, order: .reverse) private var allEntries: [ExerciseEntry]

    let entry: ExerciseEntry
    @State private var visibleCount = 6
    private let pageSize = 6

    private var isPremium: Bool {
        storeManager.isPremium
    }

    private var allFiltered: [ExerciseEntry] {
        if isPremium { return allEntries }
        let cutoff = LunixiaLimitsManager.historyCutoffDate(
            days: LunixiaLimitsManager.exerciseHistoryDaysLimit(isPremium: false)
        )
        return allEntries.filter { $0.timestamp >= cutoff }
    }

    private var visibleEntries: [ExerciseEntry] {
        Array(allFiltered.prefix(visibleCount))
    }

    private var totalCount: Int { allFiltered.count }

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Exercise History")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
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
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(visibleEntries) { e in
                            GlassCard(padding: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(e.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)

                                    HStack {
                                        Text(e.name)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(LColors.textPrimary)
                                        Spacer()
                                        HStack(spacing: 12) {
                                            Label("\(e.durationMinutes)m", systemImage: "clock.fill")
                                            Label("\(e.reps) reps", systemImage: "arrow.triangle.2.circlepath")
                                        }
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                    }
                                }
                            }
                        }

                        if totalCount > pageSize {
                            VStack(spacing: 10) {
                                if visibleCount < totalCount {
                                    Button {
                                        withAnimation { visibleCount = min(visibleCount + pageSize, totalCount) }
                                    } label: {
                                        Text("Load More")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 9)
                                            .background(LColors.accentGradient, in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }

                                if visibleCount > pageSize {
                                    Button {
                                        withAnimation { visibleCount = pageSize }
                                    } label: {
                                        Text("See Less")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(LColors.textSecondary)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 9)
                                            .background(
                                                Capsule().fill(LColors.glassSurface)
                                                    .overlay(Capsule().strokeBorder(LColors.glassBorder, lineWidth: 1))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
