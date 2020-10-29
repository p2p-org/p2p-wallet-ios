//
//  CreateWalletCompletedVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class CreateWalletCompletedVC: IntroVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    // MARK: - Subviews
    lazy var nextButton = WLButton.stepButton(type: .main, label: L10n.next)
        .onTap(self, action: #selector(buttonNextDidTouch))
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        titleLabel.text = L10n.congratulations
        descriptionLabel.text = L10n.yourWalletHasBeenSuccessfullyCreated
        
        buttonStackView.addArrangedSubview(nextButton)
    }
    
    // MARK: - Actions
    @objc func buttonNextDidTouch() {
        let nc = BENavigationController(rootViewController: PinCodeVC())
        UIApplication.shared.keyWindow?.rootViewController = nc
    }
}
