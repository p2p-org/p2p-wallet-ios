//
//  Features.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

public extension Feature {
    static let sslPinning = Feature(rawValue: "ssl_pinning")
    static let coinGeckoPriceProvider = Feature(rawValue: "coinGeckoPriceProvider")
    static let newOnboardingFlow = Feature(rawValue: "newOnboardingFlow")

    // Onboarding
    static let mockedApiGateway = Feature(rawValue: "mockedApiGateway")
    static let mockedTKeyFacade = Feature(rawValue: "mockedTKeyFacade")
}
