//
//  DependencyContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/02/2021.
//

import Foundation
import SolanaSwift

class DependencyContainer {
    // MARK: - Root
    func makeRootViewController() -> Root.ViewController {
        .init(scenesFactory: self)
    }
    
    // MARK: - CreateOrRestore wallet
    func makeCreateOrRestoreWalletViewController() -> CreateOrRestoreWalletViewController
    {
        let container: CreateOrRestoreWalletContainer = Resolver.resolve()
        return container.makeCreateOrRestoreWalletViewController()
    }
    
    // MARK: - Onboarding
    func makeOnboardingViewController() -> OnboardingViewController {
        let container: OnboardingContainer = Resolver.resolve()
        return container.makeOnboardingViewController()
    }
    
    func makeWellDoneVC() -> WellDoneVC {
        Resolver.resolve()
    }
    
    func makeWelcomeBackVC() -> WelcomeBackVC {
        Resolver.resolve()
    }
    
    // MARK: - Main
    func makeMainViewController(authenticateWhenAppears: Bool) -> MainViewController {
        let container: MainContainer = Resolver.resolve()
        return container.makeMainViewController(authenticateWhenAppears: authenticateWhenAppears)
    }
}

extension DependencyContainer: RootViewControllerScenesFactory {}
