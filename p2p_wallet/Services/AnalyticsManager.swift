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
}

struct AnalyticsManager: AnalyticsManagerType {
    init() {
        // Enable sending automatic session events
        Amplitude.instance().trackingSessionEvents = true
        // Initialize SDK
        Amplitude.instance().initializeApiKey(Bundle.main.infoDictionary!["AMPLITUDE_API_KEY"] as! String)
        // FIXME: Set userId later
//        Amplitude.instance().setUserId("userId")
    }
    
    func log(event: AnalyticsEvent) {
        // Amplitude
        if let params = event.params {
            Amplitude.instance().logEvent(event.eventName, withEventProperties: params)
        } else {
            Amplitude.instance().logEvent(event.eventName)
        }
        
    }
}
