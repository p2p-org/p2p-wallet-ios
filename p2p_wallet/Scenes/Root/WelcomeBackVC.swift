//
//  WelcomeBackVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WelcomeBackVC: WLIntroVC {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
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
        var i = 3
        let logoImageView = UIImageView(width: 150, height: 150, image: .welcomeBack)
        let spacer2 = UIView.spacer
        stackView.insertArrangedSubviewsWithCustomSpacing([
            logoImageView.centeredHorizontallyView,
            spacer2
        ], at: &i)
        
        spacer2.heightAnchor.constraint(equalTo: spacer1.heightAnchor)
            .isActive = true
        
        titleLabel.text = L10n.welcomeBack
        
        buttonsStackView.addArrangedSubviews([
            goToWalletButton,
            UIView(height: 56)
        ])
    }
    
    @objc func goToWalletButtonDidTouch() {
        analyticsManager.log(event: .restoreAccessViaSeedClick)
        analyticsManager.log(event: .loginFinishSetupClick)
        viewModel.finishSetup()
    }
}
