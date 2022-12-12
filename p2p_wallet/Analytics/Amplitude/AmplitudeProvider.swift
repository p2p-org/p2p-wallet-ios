//
//  AmplitudeProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import AnalyticsManager
import Amplitude
import Foundation

final class AmplitudeProvider: AnalyticsProvider {
    init(apiKey: String, userId: String?) {
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(apiKey)
        if let userId = userId {
            Amplitude.instance().setUserId(userId)
        }
    }

    func logEvent(_ event: NewAnalyticsEvent) {
        Amplitude.instance().logEvent(event.name, withEventProperties: event.parameters)
    }

    func setIdentifier(_ identifier: AnalyticsIdentifier) {
        guard
            let value = identifier.value as? NSObject,
            let identify = AMPIdentify().set(identifier.name, value: value)
        else { return }
        Amplitude.instance().identify(identify)
    }
}
