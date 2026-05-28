//
//  SpiritualView.swift
//  Lunixia
//

import SwiftUI
import SwiftData

struct SpiritualView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \DailyTarotRecord.updatedAt, order: .reverse)
    private var tarotRecords: [DailyTarotRecord]

    @Query(sort: \DailyLenormandRecord.updatedAt, order: .reverse)
    private var lenormandRecords: [DailyLenormandRecord]

    @State private var isDrawingTarot = false
    @State private var isDrawingLenormand = false
    @State private var tarotError: String? = nil
    @State private var lenormandError: String? = nil

    @State private var selectedHoroscopeTab: HoroscopeTab = .daily
    @State private var selectedHoroscopeSign = ""
    @State private var dailyHoroscope: DailyHoroscope? = nil
    @State private var previewHoroscope: DailyHoroscope? = nil
    @State private var isLoadingHoroscope = false
    @State private var horoscopeError: String? = nil
    @State private var horoscopeDayKey: String = ""
    @State private var horoscopeMidnightRefreshTask: Task<Void, Never>? = nil
    private let storedDailyHoroscopeKey = "storedDailyHoroscope"

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var zodiacSigns: [String] {
        [
            "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
            "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
        ]
    }

    private var currentDailyTarotTip: DailyTarotTip? {
        guard let record = tarotRecords.first(where: { $0.dayKey == todayKey }) else { return nil }
        return DailyTarotTip(id: record.tipId, title: record.title, keywords: record.keywords, message: record.message)
    }

    private var currentDailyLenormandTip: DailyLenormandTip? {
        guard let record = lenormandRecords.first(where: { $0.dayKey == todayKey }) else { return nil }
        return DailyLenormandTip(id: record.tipId, title: record.title, keywords: record.keywords, message: record.message)
    }

    // MARK: - Draw Tarot

    private func drawDailyTarotTip() {
        guard currentDailyTarotTip == nil, !isDrawingTarot else { return }
        guard let card = localDailyTarotTips.randomElement() else { return }

        isDrawingTarot = true
        tarotError = nil

        Task {
            do {
                let response = try await SpiritualService.shared.fetchTarotInterpretation(cardName: card.title)
                await MainActor.run {
                    let record = DailyTarotRecord(
                        dayKey: todayKey,
                        tipId: card.id,
                        cardName: card.title,
                        title: response.title,
                        keywords: response.keywords,
                        message: response.message
                    )
                    modelContext.insert(record)
                    try? modelContext.save()
                    isDrawingTarot = false
                }
            } catch {
                await MainActor.run {
                    tarotError = "Couldn't draw your card right now."
                    isDrawingTarot = false
                }
            }
        }
    }

    // MARK: - Draw Lenormand

    private func drawDailyLenormandTip() {
        guard currentDailyLenormandTip == nil, !isDrawingLenormand else { return }
        guard let card = localDailyLenormandTips.randomElement() else { return }

        isDrawingLenormand = true
        lenormandError = nil

        Task {
            do {
                let response = try await SpiritualService.shared.fetchLenormandInterpretation(cardName: card.title)
                await MainActor.run {
                    let record = DailyLenormandRecord(
                        dayKey: todayKey,
                        tipId: card.id,
                        cardName: card.title,
                        title: response.title,
                        keywords: response.keywords,
                        message: response.message
                    )
                    modelContext.insert(record)
                    try? modelContext.save()
                    isDrawingLenormand = false
                }
            } catch {
                await MainActor.run {
                    lenormandError = "Couldn't draw your card right now."
                    isDrawingLenormand = false
                }
            }
        }
    }
    
    // MARK: - Horoscope

    private func fetchHoroscope() {
        let trimmedSign = selectedHoroscopeSign.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSign.isEmpty else {
            horoscopeError = "Choose a zodiac sign first."
            return
        }

        horoscopeError = nil
        isLoadingHoroscope = true

        Task {
            do {
                let horoscope = try await HoroscopeService.shared.fetchHoroscope(for: trimmedSign)

                await MainActor.run {
                    if selectedHoroscopeTab == .daily {
                        dailyHoroscope = horoscope
                        horoscopeDayKey = todayKey
                        saveDailyHoroscope(horoscope)
                    } else {
                        previewHoroscope = horoscope
                    }

                    isLoadingHoroscope = false
                }
            } catch {
                await MainActor.run {
                    horoscopeError = "Couldn't load your horoscope right now."
                    isLoadingHoroscope = false
                }
            }
        }
    }

    private func resetDailyHoroscopeIfNeeded() {
        guard let stored = loadStoredDailyHoroscope() else {
            dailyHoroscope = nil
            horoscopeDayKey = todayKey
            return
        }

        if stored.dayKey == todayKey {
            dailyHoroscope = stored.horoscope
            horoscopeDayKey = stored.dayKey
        } else {
            clearStoredDailyHoroscope()
            dailyHoroscope = nil
            previewHoroscope = nil
            horoscopeError = nil
            isLoadingHoroscope = false
            selectedHoroscopeTab = .daily
            horoscopeDayKey = todayKey
        }
    }

    private func scheduleHoroscopeMidnightRefresh() {
        horoscopeMidnightRefreshTask?.cancel()

        horoscopeMidnightRefreshTask = Task { @MainActor in
            while !Task.isCancelled {
                let now = Date()
                let calendar = Calendar.autoupdatingCurrent

                guard let nextMidnight = calendar.nextDate(
                    after: now,
                    matching: DateComponents(hour: 0, minute: 0, second: 0),
                    matchingPolicy: .nextTime
                ) else {
                    return
                }

                let secondsUntilMidnight = max(1, nextMidnight.timeIntervalSince(now))

                do {
                    try await Task.sleep(for: .seconds(secondsUntilMidnight))
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }

                clearStoredDailyHoroscope()
                dailyHoroscope = nil
                previewHoroscope = nil
                horoscopeError = nil
                isLoadingHoroscope = false
                selectedHoroscopeTab = .daily
                horoscopeDayKey = todayKey
            }
        }
    }

    private func saveDailyHoroscope(_ horoscope: DailyHoroscope) {
        let stored = StoredDailyHoroscope(dayKey: todayKey, horoscope: horoscope)

        guard let data = try? JSONEncoder().encode(stored) else { return }
        UserDefaults.standard.set(data, forKey: storedDailyHoroscopeKey)
    }

    private func loadStoredDailyHoroscope() -> StoredDailyHoroscope? {
        guard let data = UserDefaults.standard.data(forKey: storedDailyHoroscopeKey) else {
            return nil
        }

        return try? JSONDecoder().decode(StoredDailyHoroscope.self, from: data)
    }

    private func clearStoredDailyHoroscope() {
        UserDefaults.standard.removeObject(forKey: storedDailyHoroscopeKey)
    }

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Nav
                HStack {
                    Text("Spiritual")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        MoonPhaseView(moonPhaseData: MoonPhaseCalculator.calculate())
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)

                        SpiritualTarotCard(
                            tip: currentDailyTarotTip,
                            isLoading: isDrawingTarot,
                            error: tarotError,
                            onDraw: drawDailyTarotTip
                        )
                        .padding(.horizontal, 16)

                        SpiritualLenormandCard(
                            tip: currentDailyLenormandTip,
                            isLoading: isDrawingLenormand,
                            error: lenormandError,
                            onDraw: drawDailyLenormandTip
                        )
                        .padding(.horizontal, 16)

                        HoroscopeView(
                            selectedTab: $selectedHoroscopeTab,
                            selectedSign: $selectedHoroscopeSign,
                            zodiacSigns: zodiacSigns,
                            dailyHoroscope: dailyHoroscope,
                            previewHoroscope: previewHoroscope,
                            isLoading: isLoadingHoroscope,
                            errorText: horoscopeError,
                            onFetch: fetchHoroscope,
                            onClearPreview: {
                                previewHoroscope = nil
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)

                        Spacer(minLength: 120)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .onAppear {
            resetDailyHoroscopeIfNeeded()
            scheduleHoroscopeMidnightRefresh()
        }
        .onDisappear {
            horoscopeMidnightRefreshTask?.cancel()
            horoscopeMidnightRefreshTask = nil
        }
    }
}

// MARK: - Tarot Card

private struct SpiritualTarotCard: View {
    let tip: DailyTarotTip?
    let isLoading: Bool
    let error: String?
    let onDraw: () -> Void

    var body: some View {
        GlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 10) {
                    Image("crystalball")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(LGradients.header)

                    Text("Daily Tarot")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    Spacer()
                }

                if let tip {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tip.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textPrimary)

                        if !tip.keywords.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("KEYWORDS")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .tracking(0.5)

                                SpiritualKeywordWrap(keywords: tip.keywords)
                            }
                        }

                        Text(tip.message)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if isLoading {
                    drawingState(label: "Drawing your card...")
                } else if let error {
                    errorState(message: error, onRetry: onDraw)
                } else {
                    emptyState(
                        prompt: "Pull your daily tarot card for today.",
                        buttonLabel: "Get Daily Card",
                        onDraw: onDraw
                    )
                }
            }
        }
    }
}

// MARK: - Lenormand Card

private struct SpiritualLenormandCard: View {
    let tip: DailyLenormandTip?
    let isLoading: Bool
    let error: String?
    let onDraw: () -> Void

    var body: some View {
        GlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 10) {
                    Image("wand")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(LGradients.header)

                    Text("Daily Lenormand")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    Spacer()
                }

                if let tip {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tip.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textPrimary)

                        if !tip.keywords.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("KEYWORDS")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .tracking(0.5)

                                SpiritualKeywordWrap(keywords: tip.keywords)
                            }
                        }

                        Text(tip.message)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if isLoading {
                    drawingState(label: "Drawing your card...")
                } else if let error {
                    errorState(message: error, onRetry: onDraw)
                } else {
                    emptyState(
                        prompt: "Draw your daily Lenormand insight for today.",
                        buttonLabel: "Draw Lenormand",
                        onDraw: onDraw
                    )
                }
            }
        }
    }
}

// MARK: - Shared sub-views

@ViewBuilder
private func drawingState(label: String) -> some View {
    HStack(spacing: 10) {
        ProgressView()
            .tint(LColors.gradientBlue)
        Text(label)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(LColors.textSecondary)
    }
    .padding(.vertical, 8)
}

@ViewBuilder
private func errorState(message: String, onRetry: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(message)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(LColors.textSecondary.opacity(0.7))

        Button { onRetry() } label: {
            Text("Try again")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(LColors.accentGradient)
                )
        }
        .buttonStyle(.plain)
    }
}

@ViewBuilder
private func emptyState(prompt: String, buttonLabel: String, onDraw: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(prompt)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(LColors.textSecondary)

        Button { onDraw() } label: {
            Text(buttonLabel)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(LColors.accentGradient)
                        .shadow(color: LColors.gradientPurple.opacity(0.35), radius: 10, y: 5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Keyword Wrap

private struct SpiritualKeywordWrap: View {
    let keywords: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunkedKeywords, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LGradients.header)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [LColors.gradientBlue, LColors.gradientPurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var chunkedKeywords: [[String]] {
        stride(from: 0, to: keywords.count, by: 3).map {
            Array(keywords[$0..<min($0 + 3, keywords.count)])
        }
    }
}
