//
//  LunixiaShortcutsProvider.swift
//  Lunixia
//

import AppIntents

struct LunixiaShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogVitalsShortcutIntent(),
            phrases: [
                "Log my vitals in \(.applicationName)",
                "Add vitals to \(.applicationName)"
            ],
            shortTitle: "Log Vitals",
            systemImageName: "heart.text.square"
        )
        AppShortcut(
            intent: LogWaterShortcutIntent(),
            phrases: [
                "Log my water in \(.applicationName)",
                "Add water to \(.applicationName)",
                "Log water intake in \(.applicationName)"
            ],
            shortTitle: "Log Water",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: LogExerciseShortcutIntent(),
            phrases: [
                "Log my exercise in \(.applicationName)",
                "Add a workout to \(.applicationName)",
                "Log a workout in \(.applicationName)"
            ],
            shortTitle: "Log Exercise",
            systemImageName: "figure.run"
        )
    }
}
