//
//  MoodStatsReportView.swift
//  Lunixia
//

import SwiftUI

struct MoodStatsReportView: View {

    let model: MoodStatsReportModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Screen Time")
                .font(.headline)

            Text("\(Int(model.totalScreenTimeMinutes)) min")

            Text("Pickups")
                .font(.headline)

            Text("\(model.pickupCount)")

            Text("Notifications")
                .font(.headline)

            Text("\(model.notificationCount)")
        }
        .padding()
    }
}
