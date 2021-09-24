//
//  OnboardingCreatePassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/03/2021.
//

import Foundation
import Resolver

extension Onboarding {
    class CreatePassCodeVC: p2p_wallet.CreatePassCodeVC {
        @Injected private var viewModel: OnboardingViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        override func viewDidLoad() {
            super.viewDidLoad()
            backButton
                .onTap(self, action: #selector(cancelOnboarding))
        }
        
        override func showConfirmPassCodeVC() {
            super.showConfirmPassCodeVC()
            analyticsManager.log(event: .setupPinKeydown1)
        }
        
        @objc func cancelOnboarding() {
            viewModel.cancelOnboarding()
        }
    }
}
