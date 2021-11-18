//
//  EnterSeedMainButtonContent.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 18.11.2021.
//

enum EnterSeedMainButtonContent {
    case valid
    case invalid(EnterSeedInvalidationReason)
}

enum EnterSeedInvalidationReason {
    case error
    case empty
}
