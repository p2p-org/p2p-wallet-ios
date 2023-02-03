//
//  AmplitudeAnalyticsProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import AnalyticsManager
import Amplitude
import Foundation

final class AmplitudeAnalyticsProvider: AnalyticsProvider {
    init(apiKey: String, userId: String?) {
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(apiKey)
        if let userId = userId {
            Amplitude.instance().setUserId(userId)
        }
    }

    func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.eventName else { return }
        Amplitude.instance().logEvent(eventName, withEventProperties: event.params)
    }

    func setIdentifier(_ identifier: AnalyticsIdentifier) {
        guard
            let value = identifier.value as? NSObject,
            let identify = AMPIdentify().set(identifier.name, value: value)
        else { return }
        Amplitude.instance().identify(identify)
    }
}
