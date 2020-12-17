//
//  CreateWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class CreateOrRestoreWalletVC: IntroVCWithButtons {
    
    lazy var createWalletButton = WLButton.stepButton(type: .blue, label: L10n.createNewWallet.uppercaseFirst)
        .onTap(self, action: #selector(buttonCreateWalletDidTouch))
    lazy var restoreWalletButton = WLButton.stepButton(type: .sub, label: L10n.iVeAlreadyHadAWallet.uppercaseFirst)
        .onTap(self, action: #selector(buttonRestoreWalletDidTouch))
    
    override func setUp() {
        super.setUp()
        
        buttonStackView.addArrangedSubview(createWalletButton)
        buttonStackView.addArrangedSubview(restoreWalletButton)
    }
    
    // MARK: - Actions
    @objc func buttonCreateWalletDidTouch() {
        showAlert(
            title: L10n.termsAndConditions,
            message: L10n.byTappingAcceptYouAgreeToP2PWalletSTermsOfUseAndPrivacyPolicy,
            buttonTitles: [L10n.cancel, L10n.accept],
            highlightedButtonIndex: 1,
            completion: { index in
                if index == 1 {
                    self.parent?.show(CreatePhrasesVC(), sender: nil)
                }
            }
        )
    }
    
    @objc func buttonRestoreWalletDidTouch() {
        self.parent?.show(RestoreWalletVC(), sender: nil)
    }
}
