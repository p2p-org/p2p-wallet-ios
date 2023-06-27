//
//  AnalyticsService.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import Foundation
import AnalyticsManager

extension AnalyticsManager {
    func log(event: KeyAppAnalyticsEvent) {
        log(event: event as AnalyticsEvent)
    }
    
    func log(parameter: KeyAppAnalyticsParameter) {
        log(parameter: parameter as AnalyticsParameter)
    }
}
