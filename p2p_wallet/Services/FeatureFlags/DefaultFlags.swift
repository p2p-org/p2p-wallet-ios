//
//  DefaultFeatureFlags.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

var defaultFlags: StaticFlagsFetcher {
    .init(
        featureFlags: [
            FeatureFlag(feature: .newOnboardingFlow, enabled: true),
            FeatureFlag(feature: .coinGeckoPriceProvider, enabled: true),
            
            // Onboarding testing
            FeatureFlag(feature: .mockedApiGateway, enabled: false),
            FeatureFlag(feature: .mockedTKeyFacade, enabled: false),
            FeatureFlag(feature: .mockedDeviceShare, enabled: false),
            FeatureFlag(feature: .simulatedSocialError, enabled: false),
            // Send via link
            FeatureFlag(feature: .sendViaLinkEnabled, enabled: false)
        ]
    )
}
