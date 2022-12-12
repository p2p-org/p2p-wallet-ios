//
//  AppsFlyerProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import AppsFlyerLib
import Foundation

final class AppsFlyerProvider: AnalyticsProvider {
    init(appsFlyerDevKey: String, appleAppID: String) {
        AppsFlyerLib.shared().appsFlyerDevKey = appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = appleAppID
    }

    func logEvent(_ event: NewAnalyticsEvent) {
        AppsFlyerLib.shared().logEvent(event.name, withValues: event.parameters)
    }
} 
