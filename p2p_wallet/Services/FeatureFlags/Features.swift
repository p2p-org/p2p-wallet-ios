//
//  Features.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

public extension Feature {
    static let sellScenarioEnabled = Feature(rawValue: "keyapp_sell_scenario_enabled")
    static let buyBankTransferEnabled = Feature(rawValue: "buy_bank_transfer_enabled")

    // Username
    static let onboardingUsernameEnabled = Feature(rawValue: "ios_onboarding_username_enabled")
    static let onboardingUsernameButtonSkipEnabled = Feature(rawValue: "ios_onboarding_username_button_skip_enabled")

    // Onboarding
    static let mockedApiGateway = Feature(rawValue: "mockedApiGateway")
    static let mockedTKeyFacade = Feature(rawValue: "mockedTKeyFacade")
    static let mockedDeviceShare = Feature(rawValue: "mockedDeviceShare")
    static let simulatedSocialError = Feature(rawValue: "simulatedSocialError")
    
    // Solend
    static let investSolendFeature = Feature(rawValue: "keyapp_invest_solend_enabled")
    static let solendDisablePlaceholder = Feature(rawValue: "ios_solend_disable_placeholder")

    // Solana tracking
    static let solanaNegativeStatus = Feature(rawValue: "solana_negative_status_enabled")
    
    // Eth
    static let ethAddressEnabled = Feature(rawValue: "eth_address_enabled")
    
    // Send via link
    static let sendViaLinkEnabled = Feature(rawValue: "send_via_link_enabled")

    static let solanaEthAddressEnabled = Feature(rawValue: "solana_eth_address_enabled")
}
