//
//  Root.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation

protocol RootViewControllerScenesFactory {
    func makeCreateOrRestoreWalletViewController() -> CreateOrRestoreWalletViewController
    func makeOnboardingViewController() -> OnboardingViewController
    func makeMainViewController(authenticateWhenAppears: Bool) -> MainViewController
    func makeWellDoneVC() -> WellDoneVC
    func makeWelcomeBackVC() -> WelcomeBackVC
}

struct Root {
    enum NavigatableScene: Equatable {
        case createOrRestoreWallet
        case onboarding
        case onboardingDone(isRestoration: Bool)
        case main
    }
}
