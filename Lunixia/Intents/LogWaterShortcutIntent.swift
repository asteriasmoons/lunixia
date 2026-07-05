//
//  LogWaterShortcutIntent.swift
//  Lunixia

import AppIntents
import SwiftData

struct LogWaterShortcutIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water"
    static var description = IntentDescription("Log a water entry in Lunixia.")

    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "Amount (oz)",
        requestValueDialog: IntentDialog("How many ounces did you drink?")
    )
    var amount: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) oz of water")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0 else {
            return .result(dialog: IntentDialog("Please enter an amount greater than 0."))
        }

        try await MainActor.run {
            let context = ModelContext(LunixiaApp.sharedModelContainer)

            let entry = WaterEntry(oz: amount)

            context.insert(entry)

            _ = try? LunixiaPointsManager.awardWaterLog(
                in: context,
                entryId: entry.id.uuidString,
                at: entry.timestamp
            )

            try context.save()
        }

        return .result(dialog: IntentDialog("Logged \(Int(amount)) oz of water."))
    }
}
