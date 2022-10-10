//
//  EnterSeedMainButtonContent.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 18.11.2021.
//

extension EnterSeed {
    enum MainButtonContent {
        case valid
        case invalid(InvalidationReason)
    }

    enum InvalidationReason {
        case error
        case empty
    }
}
