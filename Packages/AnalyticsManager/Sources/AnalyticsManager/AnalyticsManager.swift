//
//  AnalyticsManager .swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/06/2021.
//

import Foundation

public protocol AnalyticsManager {
    func log(event: AnalyticsEvent)
    func log(parameter: AnalyticsParameter)
}

public class AnalyticsManagerImpl: AnalyticsManager {
    private let providers: [AnalyticsProvider]
    
    public init(providers: [AnalyticsProvider]) {
        self.providers = providers
    }

    public func log(event: AnalyticsEvent) {
        providers.forEach { provider in
            // fillter providers to send
            guard event.providerIds.contains(provider.providerId)
            else { return }
            
            // log event to provider
            provider.logEvent(event)
        }
    }
    
    public func log(parameter: AnalyticsParameter) {
        providers.forEach { provider in
            // fillter providers to send
            guard parameter.providerIds.contains(provider.providerId)
            else { return }
            
            // log event to provider
            provider.logParameter(parameter)
        }
    }
}
