//
//  OnboardingContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class OnboardingContainer {
    @Injected private var handler: OnboardingHandler
    @Injected private var accountStorage: KeychainAccountStorage
    
    let viewModel = OnboardingViewModel()
    
    func makeOnboardingViewController() -> OnboardingViewController {
        OnboardingViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeOnboardingCreatePassCodeVC() -> OnboardingCreatePassCodeVC {
        OnboardingCreatePassCodeVC(viewModel: viewModel)
    }
    
    func makeEnableBiometryVC() -> EnableBiometryVC {
        EnableBiometryVC(onboardingViewModel: viewModel)
    }
    
    func makeEnableNotificationsVC() -> EnableNotificationsVC {
        EnableNotificationsVC(onboardingViewModel: viewModel)
    }
}

extension OnboardingContainer: OnboardingScenesFactory {}
