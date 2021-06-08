//
//  Root.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation

//protocol RootScenesFactory {
//    func makeRootDetailViewController() -> RootDetailViewController
//}

struct Root {
    enum NavigatableScene: Equatable {
        case createOrRestoreWallet
        case onboarding
        case onboardingDone(isRestoration: Bool) // FIXME: - Remove later
        case main
        case resetPincodeWithASeedPhrase
    }
}
