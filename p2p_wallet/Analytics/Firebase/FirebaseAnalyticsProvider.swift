//
//  FirebaseAnalyticsProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import Foundation
import FirebaseAnalytics

final class FirebaseAnalyticsProvider: AnalyticsProvider {
    init() {}

    func logEvent(_ event: NewAnalyticsEvent) {
        Analytics.logEvent(
            event.name,
            parameters: event.parameters.isEmpty ? nil : event.parameters
        )
    }
}
