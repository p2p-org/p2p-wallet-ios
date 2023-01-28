//
//  AnalyticsService.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import Foundation

protocol AnalyticsService: AnyObject {
    func logEvent(_ eventEvent: NewAnalyticsEvent)
}

final class AnalyticsServiceImpl: AnalyticsService {
    private let providers: [AnalyticsProvider]
    
    init(providers: [AnalyticsProvider]) {
        self.providers = providers
    }

    func logEvent(_ event: NewAnalyticsEvent) {
        providers.forEach {
            $0.logEvent(event)
        }
    }
}
