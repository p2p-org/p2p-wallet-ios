//
//  OnboardingContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class OnboardingContainer {
    let handler: OnboardingHandler
    let accountStorage: KeychainAccountStorage
    
    let viewModel: OnboardingViewModel
    
    init(
        accountStorage: KeychainAccountStorage,
        handler: OnboardingHandler
    ) {
        self.viewModel = OnboardingViewModel(accountStorage: accountStorage, handler: handler)
        self.accountStorage = accountStorage
        self.handler = handler
    }
    
    func makeOnboardingViewController() -> OnboardingViewController {
        OnboardingViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeCreatePassCodeVC() -> CreatePassCodeVC {
        CreatePassCodeVC()
    }
    
    func makeEnableBiometryVC() -> EnableBiometryVC {
        EnableBiometryVC(onboardingViewModel: viewModel)
    }
    
    func makeEnableNotificationsVC() -> EnableNotificationsVC {
        EnableNotificationsVC(onboardingViewModel: viewModel)
    }
    
    func makeWellDoneVC() -> WellDoneVC {
        WellDoneVC(onboardingViewModel: viewModel)
    }
}

extension OnboardingContainer: OnboardingScenesFactory {}
