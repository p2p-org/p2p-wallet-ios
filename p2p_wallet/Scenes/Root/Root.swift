//
//  Root.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation

struct Root {
    enum NavigatableScene: Equatable {
        case createOrRestoreWallet
        case onboarding
        case onboardingDone(isRestoration: Bool)
        case main(showAuthenticationWhenAppears: Bool)
    }
}
