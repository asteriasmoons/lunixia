//
//  DeviceActivityReport.swift
//  Lunixia
//


import DeviceActivity
import ExtensionKit
import SwiftUI

@main
@MainActor
struct LunixiaDeviceActivityReportExtension: DeviceActivityReportExtension {

    var body: some DeviceActivityReportScene {
        MoodStatsReportScene()
    }
}
