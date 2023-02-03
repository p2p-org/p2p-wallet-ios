//
//  AnalyticsService.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import Foundation
import AnalyticsManager

extension AnalyticsManager {
    func log(event: KeyAppEvent) {
        log(event: event as AnalyticsEvent)
    }
}
