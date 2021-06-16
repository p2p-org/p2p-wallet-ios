//
//  AnalyticsManager .swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/06/2021.
//

import Foundation
import Amplitude

protocol AnalyticsManagerType {
    func log(event: AnalyticsEvent)
    func log(event: AnalyticsEvent, params: [AnyHashable: Any])
}

struct AnalyticsManager: AnalyticsManagerType {
    init() {
        // Enable sending automatic session events
        Amplitude.instance().trackingSessionEvents = true
        // Initialize SDK
        Amplitude.instance().initializeApiKey("4abe05246f7563e62b5c0f1625ad5189")
        // FIXME: Set userId later
//        Amplitude.instance().setUserId("userId")
    }
    
    func log(event: AnalyticsEvent) {
        // Amplitude
        Amplitude.instance().logEvent(event.rawValue)
    }
    
    func log(event: AnalyticsEvent, params: [AnyHashable: Any]) {
        Amplitude.instance().logEvent(event.rawValue, withEventProperties: params)
    }
}
