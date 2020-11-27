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
        showAlert(
            title: L10n.termsAndConditions,
            message: L10n.byTappingAcceptYouAgreeToP2PWalletSTermsOfUseAndPrivacyPolicy,
            buttonTitles: [L10n.cancel, L10n.accept],
            highlightedButtonIndex: 1,
            completion: { index in
                if index == 1 {
                    let nc = BENavigationController(rootViewController: CreatePhrasesVC())
                    UIApplication.shared.changeRootVC(to: nc)
                }
            }
        )
    }
    
    @objc func buttonRestoreWalletDidTouch() {
        let nc = BENavigationController(rootViewController: RestoreWalletVC())
        UIApplication.shared.changeRootVC(to: nc)
    }
}
