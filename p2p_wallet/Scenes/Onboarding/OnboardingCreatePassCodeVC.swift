//
//  OnboardingCreatePassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/03/2021.
//

import Foundation

class OnboardingCreatePassCodeVC: CreatePassCodeVC {
    let viewModel: OnboardingViewModel
    
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton
            .onTap(viewModel, action: #selector(OnboardingViewModel.cancelOnboarding))
    }
    
    override func showConfirmPassCodeVC() {
        super.showConfirmPassCodeVC()
        viewModel.analyticsManager.log(event: .setupPinKeydown1)
    }
}
