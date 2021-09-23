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
    let sharedRootViewModel: Root.ViewModel
    let analyticsManager: AnalyticsManagerType
    
    init() {
        self.analyticsManager = AnalyticsManager()
        self.sharedRootViewModel = Root.ViewModel(analyticsManager: analyticsManager)
    }
    
    // MARK: - Root
    func makeRootViewController() -> Root.ViewController {
        .init(viewModel: sharedRootViewModel, scenesFactory: self)
    }
    
    // MARK: - CreateOrRestore wallet
    func makeCreateOrRestoreWalletViewController() -> CreateOrRestoreWalletViewController
    {
        let container = CreateOrRestoreWalletContainer(handler: sharedRootViewModel, analyticsManager: analyticsManager)
        return container.makeCreateOrRestoreWalletViewController()
    }
    
    // MARK: - Onboarding
    func makeOnboardingViewController() -> OnboardingViewController {
        let container = OnboardingContainer(handler: sharedRootViewModel, analyticsManager: analyticsManager)
        return container.makeOnboardingViewController()
    }
    
    func makeWellDoneVC() -> WellDoneVC {
        WellDoneVC(viewModel: sharedRootViewModel, analyticsManager: analyticsManager)
    }
    
    func makeWelcomeBackVC() -> WelcomeBackVC {
        WelcomeBackVC(viewModel: sharedRootViewModel, analyticsManager: analyticsManager)
    }
    
    // MARK: - Main
    func makeMainViewController(authenticateWhenAppears: Bool) -> MainViewController {
        let container = MainContainer(rootViewModel: sharedRootViewModel, analyticsManager: analyticsManager)
        return container.makeMainViewController(authenticateWhenAppears: authenticateWhenAppears)
    }
}

extension DependencyContainer: RootViewControllerScenesFactory {}
