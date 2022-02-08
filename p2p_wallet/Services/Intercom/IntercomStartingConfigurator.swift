//
//  IntercomStartingConfigurator.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.02.2022.
//

import Intercom

final class IntercomStartingConfigurator {
    func configure() {
        Intercom.setApiKey("ios_sdk-ea34dac95867378c8a568a970312d07a668822fc", forAppId: "imvolhpe")
        Intercom.registerUnidentifiedUser()
    }
}
