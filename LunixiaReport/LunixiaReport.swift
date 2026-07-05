//
//  LunixiaReport.swift
//  LunixiaReport
//
//  Created by Asteria Moon on 5/28/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
@MainActor
struct LunixiaReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }

        MoodStatsReportScene()
    }
}
