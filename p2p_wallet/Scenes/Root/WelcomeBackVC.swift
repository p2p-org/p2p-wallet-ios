//
//  WelcomeBackVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WelcomeBackVC: WLIntroVC {
    lazy var goToWalletButton = WLButton.stepButton(type: .blue, label: L10n.goToWallet)
        .onTap(self, action: #selector(goToWalletButtonDidTouch))
    
    let viewModel: Root.ViewModel
    let analyticsManager: AnalyticsManagerType
    init(viewModel: Root.ViewModel, analyticsManager: AnalyticsManagerType) {
        self.viewModel = viewModel
        self.analyticsManager = analyticsManager
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsManager.log(event: .setupWelcomeBackOpen)
    }
    
    override func setUp() {
        super.setUp()
        
        // add center image
        walletIntroLogo.image = .welcomeBack
        walletIntroLogo.widthConstraint?.constant = 150
        walletIntroLogo.heightConstraint?.constant = 150
        
        titleLabel.text = L10n.welcomeBack
        
        buttonsStackView.addArrangedSubviews([
            goToWalletButton,
            UIView(height: 56)
        ])
    }
    
    @objc func goToWalletButtonDidTouch() {
        viewModel.finishSetup()
    }
}
