//
//  DefaultFeatureFlags.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

public var defaultFlags = StaticFlagsFetcher(featureFlags: [])

func setupDefaultFlags() {
    defaultFlags = StaticFlagsFetcher(
        featureFlags: [
            FeatureFlag(feature: .sslPinning, enabled: true),
            FeatureFlag(feature: .newOnboardingFlow, enabled: true),

            // Onboarding testing
            FeatureFlag(feature: .mockedApiGateway, enabled: false),
            FeatureFlag(feature: .mockedTKeyFacade, enabled: false),
            FeatureFlag(feature: .mockedDeviceShare, enabled: false),
            FeatureFlag(feature: .simulatedSocialError, enabled: false),
        ]
    )
}
