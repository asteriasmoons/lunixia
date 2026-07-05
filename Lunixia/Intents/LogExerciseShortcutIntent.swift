//
//  LogExerciseShortcutIntent.swift
//  Lunixia

import AppIntents
import SwiftData

struct LogExerciseShortcutIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Exercise"
    static var description = IntentDescription("Log an exercise entry in Lunixia.")

    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "Exercise Name",
        requestValueDialog: IntentDialog("What exercise did you do?")
    )
    var name: String

    @Parameter(
        title: "Duration (minutes)",
        requestValueDialog: IntentDialog("How many minutes did you exercise?")
    )
    var durationMinutes: Int

    @Parameter(
        title: "Reps",
        requestValueDialog: IntentDialog("How many reps? Enter 0 to skip.")
    )
    var reps: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$name) for \(\.$durationMinutes) min") {
            \.$reps
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            return .result(dialog: IntentDialog("Please enter an exercise name."))
        }

        guard durationMinutes > 0 else {
            return .result(dialog: IntentDialog("Please enter a duration greater than 0."))
        }

        try await MainActor.run {
            let context = ModelContext(LunixiaApp.sharedModelContainer)

            let entry = ExerciseEntry(
                name: trimmedName,
                durationMinutes: durationMinutes,
                reps: reps ?? 0
            )

            context.insert(entry)

            _ = try? LunixiaPointsManager.awardExerciseLog(
                in: context,
                id: entry.id.uuidString,
                at: entry.timestamp
            )

            try context.save()
        }

        return .result(dialog: IntentDialog("Logged \(trimmedName) for \(durationMinutes) min."))
    }
}
