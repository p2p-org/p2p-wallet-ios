//
//  DependencyContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/02/2021.
//

import Foundation
import SolanaSwift

class DependencyContainer {
    // MARK: - Long lived dependency
    let sharedAccountStorage: KeychainAccountStorage
    let sharedRootViewModel: Root.ViewModel
    let analyticsManager: AnalyticsManager
    
    init() {
        self.sharedAccountStorage = KeychainAccountStorage()
        self.sharedRootViewModel = Root.ViewModel(accountStorage: sharedAccountStorage)
        self.analyticsManager = AnalyticsManager()
    }
    
    // MARK: - Root
    func makeRootViewController() -> Root.ViewController {
        .init(viewModel: sharedRootViewModel, scenesFactory: self)
    }
    
    // MARK: - CreateOrRestore wallet
    func makeCreateOrRestoreWalletViewController() -> CreateOrRestoreWalletViewController
    {
        let container = CreateOrRestoreWalletContainer(accountStorage: sharedAccountStorage, handler: sharedRootViewModel)
        return container.makeCreateOrRestoreWalletViewController()
    }
    
    // MARK: - Onboarding
    func makeOnboardingViewController() -> OnboardingViewController {
        let container = OnboardingContainer(accountStorage: sharedAccountStorage, handler: sharedRootViewModel)
        return container.makeOnboardingViewController()
    }
    
    func makeWellDoneVC() -> WellDoneVC {
        WellDoneVC(viewModel: sharedRootViewModel)
    }
    
    func makeWelcomeBackVC() -> WelcomeBackVC {
        WelcomeBackVC(viewModel: sharedRootViewModel)
    }
    
    // MARK: - Main
    func makeMainViewController() -> MainViewController {
        let container = MainContainer(rootViewModel: sharedRootViewModel, accountStorage: sharedAccountStorage)
        return container.makeMainViewController()
    }
    
    // MARK: - Authentication
    func makeLocalAuthVC() -> LocalAuthVC {
        LocalAuthVC(accountStorage: sharedAccountStorage)
    }
    
    // MARK: - Reset pincode with seed phrases
    func makeResetPinCodeWithSeedPhrasesViewController() -> ResetPinCodeWithSeedPhrasesViewController
    {
        let container = ResetPinCodeWithSeedPhrasesContainer(accountRepository: sharedAccountStorage)
        return container.makeResetPinCodeWithSeedPhrasesViewController()
    }
}

extension DependencyContainer: RootViewControllerScenesFactory {}
