//
//  Root.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation

enum Root {
    enum NavigatableScene: Equatable {
        case createOrRestoreWallet
        case onboarding
        case onboardingDone(isRestoration: Bool, name: String?)
        case main(showAuthenticationWhenAppears: Bool)
    }
}
