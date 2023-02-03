//
//  FirebaseAnalyticsProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import Foundation
import FirebaseAnalytics
import AnalyticsManager

final class FirebaseAnalyticsProvider: AnalyticsProvider {
    init() {}

    func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.eventName else { return }
        Analytics.logEvent(
            eventName,
            parameters: event.params
        )
    }
}
