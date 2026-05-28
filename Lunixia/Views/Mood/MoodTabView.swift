//
//  MoodTabView.swift
//  Lunixia
//

import SwiftUI
import SwiftData

struct MoodTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var storeManager: LunixiaStoreManager
    @Query(sort: \MoodEntry.timestamp, order: .reverse) private var entries: [MoodEntry]
    @Query private var chatSessions: [MoodChatSession]

    @State private var showLogSheet = false
    @State private var selectedTab: Int = 0
    @State private var selectedEntry: MoodEntry? = nil
    @State private var showBanner = false
    @State private var showChat = false
    @State private var showMoodStats = false
    @State private var showCooldownAlert = false
    
    @State private var showPremiumBanner = false
    @State private var premiumBannerMessage = ""

    private var isPremium: Bool {
        storeManager.isPremium
    }

    private var chatSession: MoodChatSession {
        if let existing = chatSessions.first { return existing }
        let new = MoodChatSession()
        modelContext.insert(new)
        return new
    }

    // MARK: Computed

    private var todayEntry: MoodEntry? {
        entries.first(where: { Calendar.current.isDateInToday($0.timestamp) })
    }
    
    private var todayMoodLogCount: Int {
        entries.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    private var canCreateMoodLog: Bool {
        LunixiaLimitsManager.canCreateMoodLog(
            todayCount: todayMoodLogCount,
            isPremium: isPremium
        )
    }

    private var visibleHistoryEntries: [MoodEntry] {
        if isPremium { return entries }

        let cutoff = LunixiaLimitsManager.historyCutoffDate(
            days: LunixiaLimitsManager.moodHistoryDaysLimit(isPremium: false)
        )

        return entries.filter { $0.timestamp >= cutoff }
    }

    private var streak: Int {
        guard !entries.isEmpty else { return 0 }
        var count = 0
        var checkDate = Calendar.current.startOfDay(for: .now)
        let calendar = Calendar.current
        while true {
            let hasEntry = entries.contains { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
            if hasEntry {
                count += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return count
    }

    private var uniqueEmotionCount: Int {
        Set(entries.flatMap { $0.emotionNames }).count
    }

    // MARK: Stats — Wellness Momentum

    private static let wellnessActivities: Set<String> = [
        "self-care", "meditation", "mindfulness", "therapy", "fitness",
        "exercise", "yoga", "swimming", "health", "hygiene", "medication",
        "sleep", "rest", "healing"
    ]

    private static let socialActivities: Set<String> = [
        "friends", "family", "dating", "community", "calls", "texting", "party"
    ]

    private static let enrichmentActivities: Set<String> = [
        "reading", "art", "music", "writing", "journaling", "hobby",
        "education", "creative", "spirituality", "religion", "mindfulness"
    ]

    private func momentumScore(for entry: MoodEntry) -> Int {
        let emotions = entry.resolvedEmotions
        let emotionScore = emotions.reduce(0) { acc, e in
            switch e.category {
            case .positive: return acc + 2
            case .neutral:  return acc + 1
            case .negative: return acc + 0
            }
        }
        let activityScore = entry.activityNames.reduce(0) { acc, name in
            if Self.wellnessActivities.contains(name)    { return acc + 2 }
            if Self.socialActivities.contains(name)      { return acc + 1 }
            if Self.enrichmentActivities.contains(name)  { return acc + 1 }
            return acc
        }
        return emotionScore + activityScore
    }

    private var sevenDayEntries: [MoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return entries.filter { $0.timestamp >= cutoff }
    }

    /// 0–100 normalised score over last 7 days.
    /// Max possible per entry: 5 emotions × 2 + 5 activities × 2 = 20; we cap at 20 per entry.
    private var sevenDayMomentum: Int {
        guard !sevenDayEntries.isEmpty else { return 0 }
        let maxPerEntry = 20
        let total = sevenDayEntries.reduce(0) { $0 + min(momentumScore(for: $1), maxPerEntry) }
        let maxPossible = sevenDayEntries.count * maxPerEntry
        return Int((Double(total) / Double(maxPossible)) * 100)
    }

    private var momentumLabel: String {
        switch sevenDayMomentum {
        case 0:       return "Nothing logged yet"
        case 1..<25:  return "Low energy"
        case 25..<50: return "Building up"
        case 50..<70: return "Steady flow"
        case 70..<90: return "Strong momentum"
        default:      return "Thriving"
        }
    }

    // Emotion breakdown for last 7 days
    private var sevenDayEmotionBreakdown: (positive: Int, neutral: Int, negative: Int) {
        let emotions = sevenDayEntries.flatMap { $0.resolvedEmotions }
        guard !emotions.isEmpty else { return (0, 0, 0) }
        let total = emotions.count
        let pos = emotions.filter { $0.category == .positive }.count
        let neu = emotions.filter { $0.category == .neutral }.count
        let neg = emotions.filter { $0.category == .negative }.count
        // Return as percentages
        return (
            Int(Double(pos) / Double(total) * 100),
            Int(Double(neu) / Double(total) * 100),
            Int(Double(neg) / Double(total) * 100)
        )
    }

    private var topEmotion: String? {
        let names = entries.flatMap { $0.emotionNames }
        guard !names.isEmpty else { return nil }
        return names.reduce(into: [:]) { $0[$1, default: 0] += 1 }
            .max(by: { $0.value < $1.value })?.key
    }

    private var topActivity: String? {
        let names = entries.flatMap { $0.activityNames }
        guard !names.isEmpty else { return nil }
        return names.reduce(into: [:]) { $0[$1, default: 0] += 1 }
            .max(by: { $0.value < $1.value })?.key
    }
    
    private func showPremiumRequiredMessage() {
        premiumBannerMessage = "Premium unlocks more mood logs."
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            showPremiumBanner = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                showPremiumBanner = false
            }
        }
    }

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Nav bar
                HStack {
                    Text("Mood")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    Spacer()
                    HStack(spacing: 14) {
                        Button {
                            if chatSession.canStartChat {
                                showChat = true
                            } else {
                                showCooldownAlert = true
                            }
                        } label: {
                            Image("chatlinesfill")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(
                                    chatSession.canStartChat
                                    ? AnyShapeStyle(LGradients.header)
                                    : AnyShapeStyle(LColors.textSecondary.opacity(0.4))
                                )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 1.5).onEnded { _ in
                                chatSession.lastChatDate = nil
                                try? modelContext.save()
                            }
                        )

                        Button {
                            showMoodStats = true
                        } label: {
                            Image("charty")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(LGradients.header)
                        }
                        .buttonStyle(.plain)

                        Button {
                            if canCreateMoodLog {
                                showLogSheet = true
                            } else {
                                showPremiumRequiredMessage()
                            }
                        } label: {
                            Image("addwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(canCreateMoodLog ? LGradients.header : LinearGradient(colors: [LColors.textSecondary.opacity(0.45)], startPoint: .top, endPoint: .bottom))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        statsCard
                            .padding(.horizontal, 16)

                        breakdownCard
                            .padding(.horizontal, 16)

                        tabPicker
                            .padding(.horizontal, 16)

                        if selectedTab == 0 {
                            todayContent
                                .padding(.horizontal, 16)
                                .transition(.opacity)
                        } else {
                            historyContent
                                .padding(.horizontal, 16)
                                .transition(.opacity)
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.top, 4)
                }
            }

            if showPremiumBanner {
                VStack {
                    Text(premiumBannerMessage)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(LColors.accentGradient)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                        .padding(.top, 18)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .completionBanner(isShowing: showBanner, message: "Mood logged!")
        .fullScreenCover(isPresented: $showLogSheet) {
            MoodLogSheet(
                todayMoodLogCount: todayMoodLogCount,
                onPremiumRequired: {
                    showPremiumRequiredMessage()
                },
                onSave: {
                    withAnimation { showBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation { showBanner = false }
                    }
                }
            )
        }
        .sheet(item: $selectedEntry) { entry in
            MoodDetailView(entry: entry)
        }
        .fullScreenCover(isPresented: $showChat) {
            MoodChatView(session: chatSession)
        }
        .fullScreenCover(isPresented: $showMoodStats) {
            MoodStatsView()
        }
        .alert("Come back soon", isPresented: $showCooldownAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            let hours = Int(chatSession.cooldownSecondsRemaining) / 3600
            let minutes = (Int(chatSession.cooldownSecondsRemaining) % 3600) / 60
            if hours > 0 {
                Text("You can talk it out again in \(hours)h \(minutes)m. Give yourself time to sit with what came up.")
            } else {
                Text("You can talk it out again in \(minutes) minute\(minutes == 1 ? "" : "s"). Give yourself time to sit with what came up.")
            }
        }
    }

    // MARK: Stats card

    private var statsCard: some View {
        GlassCard(padding: 18) {
            HStack(spacing: 0) {
                // Momentum
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(sevenDayMomentum)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("%")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                            .offset(y: -2)
                    }
                    Text(momentumLabel)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                Rectangle()
                    .fill(LColors.glassBorder)
                    .frame(width: 1, height: 44)

                Spacer()

                // Streak
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(streak)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("Day Streak")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .offset(y: -2)
                    }
                    Text(streak == 0 ? "Log today to start" : streak == 1 ? "Keep it going" : "On a roll")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.6))
                }

                Spacer()

                Rectangle()
                    .fill(LColors.glassBorder)
                    .frame(width: 1, height: 44)

                Spacer()

                // Total logs
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(entries.count)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("Logs")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .offset(y: -2)
                    }
                    Text("All time")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.6))
                }
            }
        }
    }

    // MARK: Breakdown card

    private var breakdownCard: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 16) {

                // Header row
                HStack {
                    Text("7-day snapshot")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                    Spacer()
                    if sevenDayEntries.isEmpty {
                        Text("No data yet")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.45))
                    } else {
                        Text("\(sevenDayEntries.count) log\(sevenDayEntries.count == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.45))
                    }
                }

                // Emotion bar
                if !sevenDayEntries.isEmpty {
                    let breakdown = sevenDayEmotionBreakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("emotional range")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.5))

                        GeometryReader { geo in
                            HStack(spacing: 3) {
                                if breakdown.positive > 0 {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(LinearGradient(
                                            colors: [Color(lunixiaHex: "#9B6FF7"), Color(lunixiaHex: "#7d19f7")],
                                            startPoint: .leading, endPoint: .trailing
                                        ))
                                        .frame(width: geo.size.width * CGFloat(breakdown.positive) / 100)
                                }
                                if breakdown.neutral > 0 {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(LinearGradient(
                                            colors: [Color(lunixiaHex: "#03dbfc"), Color(lunixiaHex: "#00b8d9")],
                                            startPoint: .leading, endPoint: .trailing
                                        ))
                                        .frame(width: geo.size.width * CGFloat(breakdown.neutral) / 100)
                                }
                                if breakdown.negative > 0 {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(LinearGradient(
                                            colors: [Color(lunixiaHex: "#e019d4"), Color(lunixiaHex: "#b8009e")],
                                            startPoint: .leading, endPoint: .trailing
                                        ))
                                        .frame(width: geo.size.width * CGFloat(breakdown.negative) / 100)
                                }
                            }
                            .frame(height: 10)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        .frame(height: 10)

                        HStack(spacing: 14) {
                            breakdownLegendDot(color: Color(lunixiaHex: "#9B6FF7"), label: "positive", value: breakdown.positive)
                            breakdownLegendDot(color: Color(lunixiaHex: "#03dbfc"), label: "neutral",  value: breakdown.neutral)
                            breakdownLegendDot(color: Color(lunixiaHex: "#e019d4"), label: "negative", value: breakdown.negative)
                        }
                    }

                    Rectangle()
                        .fill(LColors.glassBorder)
                        .frame(height: 1)
                }

                // Top emotion + activity row
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("most felt")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.5))
                        Text(topEmotion ?? "—")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                    }

                    Spacer()

                    Rectangle()
                        .fill(LColors.glassBorder)
                        .frame(width: 1, height: 36)

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("top activity")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.5))
                        Text(topActivity ?? "—")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func breakdownLegendDot(color: Color, label: String, value: Int) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text("\(value)% \(label)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.textSecondary.opacity(0.55))
        }
    }

    // MARK: Tab picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(["Today", "History"], id: \.self) { tab in
                let index = tab == "Today" ? 0 : 1
                let isSelected = selectedTab == index

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                } label: {
                    Text(tab)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : LColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(LColors.accentGradient)
                                        .shadow(color: LColors.gradientPurple.opacity(0.3), radius: 8, y: 4)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LColors.glassSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                )
        )
    }

    // MARK: Today

    @ViewBuilder
    private var todayContent: some View {
        if let entry = todayEntry {
            MoodLogCard(entry: entry) { selectedEntry = entry }
        } else {
            emptyState(message: "No mood logged today yet")
        }
    }

    // MARK: History

    @ViewBuilder
    private var historyContent: some View {
        if visibleHistoryEntries.isEmpty {
            emptyState(message: "Your mood logs will appear here")
        } else {
            VStack(spacing: 12) {
                ForEach(visibleHistoryEntries) { entry in
                    MoodLogCard(entry: entry) { selectedEntry = entry }
                }
            }
        }
    }

    // MARK: Empty state

    @ViewBuilder
    private func emptyState(message: String) -> some View {
        VStack(spacing: 14) {
            Image("xsmile")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(LColors.textSecondary.opacity(0.4))
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.textSecondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Mood Log Card

struct MoodLogCard: View {
    let entry: MoodEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GlassCard(padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                        Spacer()
                        Image("chevright")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(LColors.textSecondary.opacity(0.5))
                    }

                    if !entry.resolvedEmotions.isEmpty {
                        FlowLayout(spacing: 5) {
                            ForEach(entry.resolvedEmotions.prefix(6)) { emotion in
                                let colors = emotion.category.bubbleColors
                                Text(emotion.name)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(lunixiaHex: colors.Color1).opacity(0.82),
                                                        Color(lunixiaHex: colors.Color2).opacity(0.65)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                            }
                            if entry.resolvedEmotions.count > 6 {
                                Text("+\(entry.resolvedEmotions.count - 6)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(LColors.glassSurface2))
                            }
                        }
                    }

                    if !entry.resolvedActivities.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(entry.resolvedActivities.prefix(8)) { activity in
                                Group {
                                    if activity.isCustomAsset {
                                        Image(activity.icon)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                    } else {
                                        Image(systemName: activity.icon)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                }
                                .foregroundStyle(LColors.textSecondary.opacity(0.7))
                            }
                            if entry.resolvedActivities.count > 8 {
                                Text("+\(entry.resolvedActivities.count - 8)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary.opacity(0.5))
                            }
                        }
                    }

                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.7))
                            .lineLimit(2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
