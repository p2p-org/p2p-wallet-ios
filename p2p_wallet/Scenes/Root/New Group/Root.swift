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
    func makeMainViewController() -> MainViewController
    func makeLocalAuthVC() -> LocalAuthVC
    func makeWellDoneVC() -> WellDoneVC
    func makeWelcomeBackVC() -> WelcomeBackVC
    func makeResetPinCodeWithSeedPhrasesViewController() -> ResetPinCodeWithSeedPhrasesViewController
}

struct Root {
    enum NavigatableScene: Equatable {
        case createOrRestoreWallet
        case onboarding
        case onboardingDone(isRestoration: Bool) // FIXME: - Remove later
        case main
        case resetPincodeWithASeedPhrase
    }
}
