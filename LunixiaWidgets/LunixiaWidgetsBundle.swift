//
//  LunixiaWidgetsBundle.swift
//  LunixiaWidgets
//
//  Created by Asteria Moon on 6/3/26.
//

import WidgetKit
import SwiftUI

@main
struct LunixiaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LunixiaHealthWaterSmallWidget()
        LunixiaHealthStepsSmallWidget()
        LunixiaHealthMediumWidget()
        LunixiaBodyEmotionMediumWidget()
        LunixiaBodyEmotionLargeWidget()
        LunixiaHealthLargeWidget()
        LunixiaHealthAccessoryRectWidget()
        LunixiaMoodMediumWidget()
        LunixiaMoodLargeWidget()
        LunixiaHealthVitalsMediumWidget()
        LunixiaPointsLargeWidget()
        LunixiaPointsMediumWidget()
        LunixiaMoonPhaseMediumWidget()
    }
}
