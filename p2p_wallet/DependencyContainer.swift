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
    
    init() {
        self.sharedAccountStorage = KeychainAccountStorage()
        self.sharedRootViewModel = Root.ViewModel(accountStorage: sharedAccountStorage)
    }
    
    // MARK: - Root
    func makeRootViewController() -> Root.ViewController {
        return .init(viewModel: sharedRootViewModel, scenesFactory: self)
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
    func makeMainViewController(authenticateWhenAppears: Bool) -> MainViewController {
        let container = MainContainer(rootViewModel: sharedRootViewModel, accountStorage: sharedAccountStorage)
        return container.makeMainViewController(authenticateWhenAppears: authenticateWhenAppears)
    }
}

extension DependencyContainer: RootViewControllerScenesFactory {}
