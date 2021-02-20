//
//  WellDoneVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WellDoneVC: BaseOnboardingVC {
    let onboardingViewModel: OnboardingViewModel
    init(onboardingViewModel: OnboardingViewModel) {
        self.onboardingViewModel = onboardingViewModel
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        titleLabel.text = L10n.wellDone
        descriptionLabel.text = L10n.exploreP2PWalletAndDepositFundsWhenYouReReady
        
        acceptButton.setTitle(L10n.finishSetup, for: .normal)
        doThisLaterButton.alpha = 0
    }
    
    override func buttonAcceptDidTouch() {
        onboardingViewModel.endOnboarding()
    }
}
