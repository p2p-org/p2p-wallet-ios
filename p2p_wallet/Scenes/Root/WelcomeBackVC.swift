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
        .onTap(viewModel, action: #selector(Root.ViewModel.navigateToMain))
    
    let viewModel: Root.ViewModel
    init(viewModel: Root.ViewModel) {
        self.viewModel = viewModel
        super.init()
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
}

