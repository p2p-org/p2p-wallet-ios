//
//  CreateWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class CreateOrRestoreWalletVC: IntroVCWithButtons {
    
    lazy var createWalletButton = WLButton.stepButton(type: .main, label: L10n.createNewWallet.uppercaseFirst)
        .onTap(self, action: #selector(buttonCreateWalletDidTouch))
    lazy var restoreWalletButton = WLButton.stepButton(type: .sub, label: L10n.iVeAlreadyHadAWallet.uppercaseFirst)
        .onTap(self, action: #selector(buttonRestoreWalletDidTouch))
    
    override func setUp() {
        super.setUp()
        descriptionLabel.isHidden = true
        
        buttonStackView.addArrangedSubview(createWalletButton)
        buttonStackView.addArrangedSubview(restoreWalletButton)
    }
    
    // MARK: - Actions
    @objc func buttonCreateWalletDidTouch() {
        parent?.present(TermsAndConditionsVC(), animated: true, completion: nil)
    }
    
    @objc func buttonRestoreWalletDidTouch() {
        parent?.show(RestoreWalletVC(), sender: nil)
    }
}
