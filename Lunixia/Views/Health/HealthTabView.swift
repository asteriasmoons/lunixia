//
//  HealthTabView.swift
//  Lunixia
//

import SwiftUI
import SwiftData
import HealthKit
import Combine

struct HealthTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var storeManager: LunixiaStoreManager
    @Query(sort: \VitalsEntry.timestamp, order: .reverse) private var vitalsEntries: [VitalsEntry]
    @Query(sort: \ExerciseEntry.timestamp, order: .reverse) private var exerciseEntries: [ExerciseEntry]
    @Query(sort: \WaterEntry.timestamp, order: .reverse) private var waterEntries: [WaterEntry]
    @Query private var goals: [HealthGoals]

    @State private var showVitalsLog = false
    @State private var showExerciseLog = false
    @State private var showWaterLog = false
    @State private var showWaterClear = false
    @State private var showGoalSheet = false
    @State private var selectedVitals: VitalsEntry? = nil
    @State private var selectedExercise: ExerciseEntry? = nil
    @State private var showBanner = false
    @State private var bannerMessage = ""
    @State private var todaySteps: Int = 0
    @State private var healthKitWaterOz: Double = 0
    @State private var showWaterGoalCelebration = false
    @State private var displayedHealthDay = Calendar.current.startOfDay(for: Date())
    private var isPremium: Bool {
        storeManager.isPremium
    }

    private var currentGoals: HealthGoals {
        goals.first ?? HealthGoals()
    }

    private var localWaterOz: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return waterEntries
            .filter { $0.timestamp >= today }
            .reduce(0) { $0 + $1.oz }
    }

    private var todayWaterOz: Double {
        max(localWaterOz, healthKitWaterOz)
    }

    private var todayExercises: [ExerciseEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return exerciseEntries.filter { $0.timestamp >= today }
    }

    private var todayExerciseLogCount: Int {
        todayExercises.count
    }

    private var canCreateExerciseLog: Bool {
        LunixiaLimitsManager.canCreateExerciseLog(
            todayCount: todayExerciseLogCount,
            isPremium: isPremium
        )
    }

    private var visibleExerciseEntries: [ExerciseEntry] {
        if isPremium {
            return exerciseEntries
        }

        let cutoff = LunixiaLimitsManager.historyCutoffDate(
            days: LunixiaLimitsManager.exerciseHistoryDaysLimit(isPremium: false)
        )

        return exerciseEntries.filter { $0.timestamp >= cutoff }
    }

    private var todayVitals: VitalsEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return vitalsEntries.first { $0.timestamp >= today }
    }

    private var todayVitalsEntries: [VitalsEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return vitalsEntries.filter { $0.timestamp >= today }
    }

    private var todayVitalsEntryCount: Int {
        todayVitalsEntries.count
    }

    private var canCreateVitalsEntry: Bool {
        LunixiaLimitsManager.canCreateCompleteVitalsEntry(
            todayCount: todayVitalsEntryCount,
            isPremium: isPremium
        )
    }

    private var visibleVitalsEntries: [VitalsEntry] {
        if isPremium {
            return vitalsEntries
        }

        let cutoff = LunixiaLimitsManager.historyCutoffDate(
            days: LunixiaLimitsManager.vitalsHistoryDaysLimit(isPremium: false)
        )

        return vitalsEntries.filter { $0.timestamp >= cutoff }
    }

    var body: some View {
        NavigationStack {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Nav
                HStack {
                    Text("Health")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    Spacer()
                    Button {
                        ensureGoalsExist()
                        showGoalSheet = true
                    } label: {
                        Image("goalsparkle")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(LGradients.header)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {

                        // MARK: Vitals card
                        vitalsCard
                            .padding(.horizontal, 16)

                        // MARK: Exercise card
                        exerciseCard
                            .padding(.horizontal, 16)

                        // MARK: Water card
                        waterCard
                            .padding(.horizontal, 16)

                        // MARK: Steps card
                        stepsCard
                            .padding(.horizontal, 16)

                        // MARK: Medications card
                        NavigationLink(destination: MedicationPageView()) {
                            medicationsEntryCard
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        // MARK: Symptom Logger card
                        NavigationLink(destination: SymptomLoggerView()) {
                            symptomLoggerEntryCard
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        Spacer(minLength: 120)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .completionBanner(isShowing: showBanner, message: bannerMessage)
        .overlay {
            if showWaterGoalCelebration {
                WaterGoalCelebrationOverlay()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .sheet(isPresented: $showVitalsLog) {
            VitalsLogSheet(
                todayVitalsEntryCount: todayVitalsEntryCount,
                onPremiumRequired: {
                    showPremiumRequiredMessage()
                },
                onSave: { entry in
                    guard canCreateVitalsEntry else {
                        showPremiumRequiredMessage()
                        return
                    }
                    modelContext.insert(entry)
                    try? modelContext.save()
                    writeVitalsToHealthKit(entry)
                    _ = try? LunixiaPointsManager.awardVitalsLog(in: modelContext, id: entry.id.uuidString, at: entry.timestamp)
                    flash("Vitals logged!")
                }
            )
        }
        .sheet(isPresented: $showExerciseLog) {
            ExerciseLogSheet(
                todayExerciseLogCount: todayExerciseLogCount,
                onPremiumRequired: {
                    showPremiumRequiredMessage()
                },
                onSave: { entry in
                    modelContext.insert(entry)
                    try? modelContext.save()
                    writeExerciseToHealthKit(entry)
                    _ = try? LunixiaPointsManager.awardExerciseLog(in: modelContext, id: entry.id.uuidString, at: entry.timestamp)
                    flash("Exercise logged!")
                }
            )
        }
        .sheet(isPresented: $showWaterLog) {
            WaterLogSheet(currentGoalOz: currentGoals.dailyWaterOz) { oz in
                let entry = WaterEntry(oz: oz)
                modelContext.insert(entry)
                try? modelContext.save()
                writeWaterToHealthKit(oz)
                checkWaterGoalCelebration(
                    previousWaterOz: max(localWaterOz - oz, healthKitWaterOz),
                    addedWaterOz: oz
                )
                refreshHealthKitTotalsSoon()
                _ = try? LunixiaPointsManager.awardWaterLog(in: modelContext, entryId: entry.id.uuidString)
                flash("\(Int(oz))oz logged!")
            }
        }
        .sheet(isPresented: $showWaterClear) {
            WaterClearSheet(currentWaterOz: todayWaterOz) { oz in
                clearWaterAmount(oz)
                refreshHealthKitTotalsSoon()
                flash("\(Int(oz))oz cleared!")
            }
        }
        .sheet(isPresented: $showGoalSheet) {
            GoalSheet(goals: currentGoals) {
                ensureGoalsExist()
                try? modelContext.save()
                flash("Goals saved!")
            }
        }
        .sheet(item: $selectedVitals) { entry in
            VitalsDetailView(entry: entry)
        }
        .sheet(item: $selectedExercise) { entry in
            ExerciseDetailView(entry: entry)
        }
        .task {
            ensureGoalsExist()
            resetDisplayedHealthTotalsIfNeeded()
            await refreshHealthKitTotals()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            resetDisplayedHealthTotalsIfNeeded()
            refreshHealthKitTotalsSoon()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            resetDisplayedHealthTotalsIfNeeded()
        }
        } // end NavigationStack
    }

    // MARK: - Vitals Card

    private var vitalsCard: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    cardLabel(icon: "scope", text: "Vitals")
                    Spacer()
                    HStack(spacing: 10) {
                        if !visibleVitalsEntries.isEmpty {
                            Button {
                                selectedVitals = visibleVitalsEntries.first
                            } label: {
                                Image("clockfill")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundStyle(LColors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            if canCreateVitalsEntry {
                                showVitalsLog = true
                            } else {
                                showPremiumRequiredMessage()
                            }
                        } label: {
                            Image("addwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(canCreateVitalsEntry ? LGradients.header : LinearGradient(colors: [LColors.textSecondary.opacity(0.45)], startPoint: .top, endPoint: .bottom))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let v = todayVitals {
                    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                        GridRow {
                            vitalsTile(label: "SpO2", value: v.bloodOxygen == 0 ? "--" : "\(Int(v.bloodOxygen))%")
                            vitalsTile(label: "Systolic", value: v.systolic == 0 ? "--" : "\(Int(v.systolic))")
                            vitalsTile(label: "Diastolic", value: v.diastolic == 0 ? "--" : "\(Int(v.diastolic))")
                        }

                        GridRow {
                            vitalsTile(label: "BPM", value: v.bpm == 0 ? "--" : "\(Int(v.bpm)) bpm")
                            vitalsTile(label: "Temp", value: v.bodyTemp == 0 ? "--" : String(format: "%.1f°F", v.bodyTemp))
                            vitalsTile(label: "Weight", value: v.weight == 0 ? "--" : String(format: "%.1f lbs", v.weight))
                        }
                    }
                } else {
                    emptyRow(message: "No vitals logged today")
                }
            }
        }
    }

    // MARK: - Exercise Card

    private var exerciseCard: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    cardLabel(icon: "dumbbell", text: "Exercise")
                    Spacer()
                    HStack(spacing: 10) {
                        if visibleExerciseEntries.count > 0 {
                            Button {
                                selectedExercise = visibleExerciseEntries.first
                            } label: {
                                Image("clockfill")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundStyle(LColors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            if canCreateExerciseLog {
                                showExerciseLog = true
                            } else {
                                showPremiumRequiredMessage()
                            }
                        } label: {
                            Image("addwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(canCreateExerciseLog ? LGradients.header : LinearGradient(colors: [LColors.textSecondary.opacity(0.45)], startPoint: .top, endPoint: .bottom))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if todayExercises.isEmpty {
                    emptyRow(message: "No exercise logged today")
                } else {
                    VStack(spacing: 8) {
                        ForEach(todayExercises.prefix(3)) { entry in
                            HStack {
                                Text(entry.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textPrimary)
                                Spacer()
                                Text("\(entry.durationMinutes)m · \(entry.reps) reps")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(LColors.glassSurface)
                            )
                        }
                        if todayExercises.count > 3 {
                            Text("+\(todayExercises.count - 3) more")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Water Card

    private var waterCard: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    cardLabel(icon: "bottle", text: "Water")
                    Spacer()
                    Button { showWaterLog = true } label: {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(LGradients.header)
                    }
                    .buttonStyle(.plain)
                }

                // Progress bar
                let progress = min(todayWaterOz / currentGoals.dailyWaterOz, 1.0)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(String(format: "%.0f oz", todayWaterOz))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("/ \(Int(currentGoals.dailyWaterOz)) oz goal")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .padding(.top, 4)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(LColors.glassSurface2)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(LColors.accentGradient)
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }

                // Quick log buttons
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 104), spacing: 10)
                    ],
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach([8.0, 20.0], id: \.self) { oz in
                        Button {
                            let entry = WaterEntry(oz: oz)
                            modelContext.insert(entry)
                            try? modelContext.save()
                            writeWaterToHealthKit(oz)
                            checkWaterGoalCelebration(
                                previousWaterOz: max(localWaterOz - oz, healthKitWaterOz),
                                addedWaterOz: oz
                            )
                            refreshHealthKitTotalsSoon()
                            _ = try? LunixiaPointsManager.awardWaterLog(in: modelContext, entryId: entry.id.uuidString)
                            flash("\(Int(oz))oz logged!")
                        } label: {
                            Text("+\(Int(oz)) oz")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(LColors.accentGradient)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showWaterLog = true
                    } label: {
                        Text("+ Custom")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(LColors.glassSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showWaterClear = true
                    } label: {
                        Text("Clear Custom")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(LColors.glassSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Steps Card

    private var stepsCard: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                cardLabel(icon: "shoe", text: "Steps")

                let progress = min(Double(todaySteps) / Double(currentGoals.dailySteps), 1.0)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(todaySteps)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("/ \(currentGoals.dailySteps) goal")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .padding(.top, 4)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(LColors.glassSurface2)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(LColors.accentGradient)
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text(stepsSubtitle(steps: todaySteps, goal: currentGoals.dailySteps))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Medications Entry Card

    private var medicationsEntryCard: some View {
        GlassCard(padding: 18) {
            HStack(spacing: 9) {
                Image("medication")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(LGradients.header)
                Text("Medications")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                Spacer()
                Image("chevright")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(LColors.textSecondary.opacity(0.45))
            }
        }
    }

    // MARK: - Symptom Logger Entry Card

    private var symptomLoggerEntryCard: some View {
        GlassCard(padding: 18) {
            HStack(spacing: 9) {
                Image("medsymbol")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(LGradients.header)
                Text("Symptom Log")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                Spacer()
                Image("chevright")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(LColors.textSecondary.opacity(0.45))
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func cardLabel(icon: String, text: String) -> some View {
        HStack(spacing: 9) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(LGradients.header)
            Text(text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
    }

    @ViewBuilder
    private func vitalsTile(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
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

    @ViewBuilder
    private func emptyRow(message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(LColors.textSecondary.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }

    private func stepsSubtitle(steps: Int, goal: Int) -> String {
        let remaining = goal - steps
        if remaining <= 0 { return "goal reached" }
        return "\(remaining) steps to go"
    }

    private func ensureGoalsExist() {
        guard goals.isEmpty else { return }
        modelContext.insert(HealthGoals())
        try? modelContext.save()
    }

    private func resetDisplayedHealthTotalsIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        guard displayedHealthDay != today else { return }

        displayedHealthDay = today
        todaySteps = 0
        healthKitWaterOz = 0
    }

    private func refreshHealthKitTotals() async {
        async let steps = HealthKitManager.shared.fetchStepsToday()
        async let water = HealthKitManager.shared.fetchWaterToday()

        let totals = await (steps, water)

        await MainActor.run {
            displayedHealthDay = Calendar.current.startOfDay(for: Date())
            todaySteps = totals.0
            healthKitWaterOz = totals.1

            let dk = LunixiaPointsManager.dayKey()

            // Water goal points are awarded from refreshed totals.
            let waterGoal = currentGoals.dailyWaterOz
            if waterGoal > 0 && max(localWaterOz, totals.1) >= Double(waterGoal) {
                _ = try? LunixiaPointsManager.awardWaterGoal(in: modelContext, dayKey: dk)
            }

            // Step goal
            let stepGoal = currentGoals.dailySteps
            if stepGoal > 0 && totals.0 >= stepGoal {
                _ = try? LunixiaPointsManager.awardStepGoal(in: modelContext, dayKey: dk)
            }
        }
    }

    private func checkWaterGoalCelebration(previousWaterOz: Double, addedWaterOz: Double) {
        let waterGoal = currentGoals.dailyWaterOz
        guard waterGoal > 0 else { return }

        let newTotal = previousWaterOz + addedWaterOz
        let reachedGoal = previousWaterOz < Double(waterGoal) && newTotal >= Double(waterGoal)

        if reachedGoal {
            showWaterGoalCelebrationNow()
        }
    }

    private func showWaterGoalCelebrationNow() {
        withAnimation(.easeOut(duration: 0.25)) {
            showWaterGoalCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showWaterGoalCelebration = false
            }
        }
    }

    private func refreshHealthKitTotalsSoon() {
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            await refreshHealthKitTotals()
        }
    }

    private func clearWaterAmount(_ oz: Double) {
        guard oz > 0 else { return }
        let today = Calendar.current.startOfDay(for: Date())
        var remaining = oz
        
        let todaysEntries = waterEntries
            .filter { $0.timestamp >= today }
            .sorted { $0.timestamp > $1.timestamp }
        
        for entry in todaysEntries where remaining > 0 {
            if entry.oz <= remaining + 0.001 {
                remaining -= entry.oz
                modelContext.delete(entry)
            } else {
                entry.oz -= remaining
                remaining = 0
            }
        }
        
        try? modelContext.save()
        deleteWaterFromHealthKit(oz)
    }

    private func deleteWaterFromHealthKit(_ oz: Double) {
        guard oz > 0,
              HKHealthStore.isHealthDataAvailable(),
              let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else { return }
        
        let store = HKHealthStore()
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: waterType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ) { _, samples, error in
            guard error == nil,
                  let quantitySamples = samples as? [HKQuantitySample] else { return }
            
            let unit = HKUnit.fluidOunceUS()
            var remaining = oz
            var samplesToDelete: [HKQuantitySample] = []
            
            for sample in quantitySamples where remaining > 0 {
                let sampleOz = sample.quantity.doubleValue(for: unit)
                samplesToDelete.append(sample)
                remaining -= sampleOz
            }
            
            guard !samplesToDelete.isEmpty else { return }
            store.delete(samplesToDelete) { success, error in
                if let error {
                    print("HealthKit water delete error: \(error)")
                } else {
                    print("HealthKit water delete success: \(success)")
                }
            }
        }
        
        store.execute(query)
    }

    private func writeVitalsToHealthKit(_ entry: VitalsEntry) {
        Task {
            await HealthKitWriteManager.shared.writeVitals(entry: entry)
        }
    }

    private func writeExerciseToHealthKit(_ entry: ExerciseEntry) {
        Task {
            await HealthKitWriteManager.shared.writeExercise(entry: entry)
        }
    }

    private func writeWaterToHealthKit(_ oz: Double) {
        Task {
            await HealthKitWriteManager.shared.writeWater(oz: oz)
        }
    }

    private func showPremiumRequiredMessage() {
        flash("Premium unlocks more health logs.")
    }

    private func flash(_ message: String) {
        bannerMessage = message
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { showBanner = false }
        }
    }
}

// MARK: - Water Clear Sheet

struct WaterClearSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentWaterOz: Double
    let onClear: (Double) -> Void
    
    @State private var amountText = ""
    
    private var amount: Double {
        Double(amountText) ?? 0
    }
    
    private var clampedAmount: Double {
        min(max(amount, 0), currentWaterOz)
    }
    
    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clear Water")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Remove a custom amount from today’s water total.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image("xmarkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                            .foregroundStyle(LGradients.header)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(LColors.glassSurface2))
                    }
                    .buttonStyle(.plain)
                }
                
                GlassCard(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Current water")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                        
                        Text("\(Int(currentWaterOz)) oz")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        
                        TextField("Amount to clear", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                                    .fill(LColors.glassSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                                    .strokeBorder(LColors.glassBorder, lineWidth: 1)
                            )
                        
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 88), spacing: 10)],
                            alignment: .leading,
                            spacing: 10
                        ) {
                            ForEach([8.0, 16.0, 20.0, currentWaterOz], id: \.self) { oz in
                                Button {
                                    amountText = String(Int(oz))
                                } label: {
                                    Text(oz == currentWaterOz ? "Clear All" : "\(Int(oz)) oz")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(LColors.glassSurface2)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    guard clampedAmount > 0 else { return }
                    onClear(clampedAmount)
                    dismiss()
                } label: {
                    Text("Clear \(Int(clampedAmount)) oz")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LColors.accentGradient)
                        )
                }
                .buttonStyle(.plain)
                .opacity(clampedAmount > 0 ? 1 : 0.45)
                .disabled(clampedAmount <= 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - Water Goal Celebration

struct WaterGoalCelebrationOverlay: View {
    @State private var animate = false

    private let confettiPieces = Array(0..<42)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.opacity(0.001)
                    .ignoresSafeArea()

                ForEach(confettiPieces, id: \.self) { index in
                    let x = CGFloat.random(in: 20...(geo.size.width - 20))
                    let delay = Double.random(in: 0...0.8)
                    let width = CGFloat.random(in: 5...10)
                    let height = CGFloat.random(in: 12...24)
                    let cornerRadius = CGFloat.random(in: 2...5)
                    let rotation = Double.random(in: -240...240)
                    let duration = Double.random(in: 1.5...2.4)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue,
                                    LColors.gradientPurple,
                                    Color.white.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: width, height: height)
                        .rotationEffect(.degrees(animate ? rotation : 0))
                        .position(
                            x: x,
                            y: animate
                                ? geo.size.height + 80
                                : -60
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeIn(duration: duration)
                            .delay(delay),
                            value: animate
                        )
                }

                VStack(spacing: 10) {
                    Text("Water Goal Reached")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)

                    Text("You hydrated like a legend today.")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 20, y: 10)
            }
            .onAppear {
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}
