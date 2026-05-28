//
//  LunixiaApp.swift
//  Lunixia
//

import SwiftUI
import SwiftData

@main
struct LunixiaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var storeManager = LunixiaStoreManager()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            MoodEntry.self,
            VitalsEntry.self,
            ExerciseEntry.self,
            WaterEntry.self,
            HealthGoals.self,
            DailyHoroscopeRecord.self,
            DailyTarotRecord.self,
            DailyLenormandRecord.self,
            TarotPullRecord.self,
            LenormandPullRecord.self,
            AuthUser.self,
            Note.self,
            NotesTab.self,
            DailyIntention.self,
            JournalBlock.self,
            JournalBook.self,
            JournalEntry.self,
            JournalPrompt.self,
            JournalPromptUsage.self,
            JournalStats.self,
            JournalInlineStyle.self,
            UserSettings.self,
            LunixiaMedication.self,
            LunixiaMedHistoryEntry.self,
            LunixiaSymptomLog.self,
            LunixiaPointEntry.self,
            LunixiaPointsProfile.self,
            LunixiaPointsResetLog.self,
            MoodChatSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(storeManager)
                .task {
                    await MainActor.run {
                        LunixiaPointsManager.scheduleWeeklyReset(modelContainer: sharedModelContainer)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
