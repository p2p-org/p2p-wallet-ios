//
//  AnalyticsManager .swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/06/2021.
//

import Amplitude
import Foundation

protocol AnalyticsManagerType {
    func log(event: AnalyticsEvent)
}

class AnalyticsManager: AnalyticsManagerType {
    init() {
        // Enable sending automatic session events
        Amplitude.instance().trackingSessionEvents = true
        // Initialize SDK
        Amplitude.instance().initializeApiKey(.secretConfig("AMPLITUDE_API_KEY")!)
        // FIXME: Set userId later
//        Amplitude.instance().setUserId("userId")
    }

    func log(event: AnalyticsEvent) {
        guard let eventName = event.eventName else { return }
        // Amplitude
        if let params = event.params {
            debugPrint([eventName, params])
            Amplitude.instance().logEvent(eventName, withEventProperties: params)
        } else {
            debugPrint([eventName])
            Amplitude.instance().logEvent(eventName)
        }
    }
}
