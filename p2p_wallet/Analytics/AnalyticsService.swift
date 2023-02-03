//
//  AnalyticsService.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import Foundation
import AnalyticsManager

protocol AnalyticsService: AnyObject {
    func logEvent(_ event: AnalyticsEvent)
}

extension AnalyticsService {
    func logEvent(_ event: KeyAppEvent) {
        logEvent(event as AnalyticsEvent)
    }
}

final class AnalyticsServiceImpl: AnalyticsService {
    private let providers: [AnalyticsProvider]
    
    init(providers: [AnalyticsProvider]) {
        self.providers = providers
    }

    func logEvent(_ event: AnalyticsEvent) {
        providers.forEach {
            $0.logEvent(event)
        }
    }
}

// TODO: - Remove later
extension AnalyticsManager {
    func log(event: KeyAppEvent) {
        log(event: event as AnalyticsEvent)
    }
}
