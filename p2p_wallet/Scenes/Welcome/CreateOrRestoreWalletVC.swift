//
//  CreateWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class CreateOrRestoreWalletVC: IntroVC {
    override var index: Int {1}
    
    lazy var createWalletButton = WLButton.stepButton(type: .main, label: L10n.createNewWallet.uppercaseFirst)
        .onTap(self, action: #selector(buttonCreateWalletDidTouch))
    lazy var restoreWalletButton = WLButton.stepButton(type: .sub, label: L10n.iVeAlreadyHadAWallet.uppercaseFirst)
    
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
                    UIApplication.shared.keyWindow?.showIndetermineHudWithMessage(L10n.creatingAnAccount.uppercaseFirst)
                    DispatchQueue.global().async {
                        do {
                            let account = try SolanaSDK.Account()
                            DispatchQueue.main.async {
                                UIApplication.shared.keyWindow?.hideHud()
                                let nc = BENavigationController(rootViewController: CreateWalletVC(account: account))
                                UIApplication.shared.keyWindow?.rootViewController = nc
                            }
                        } catch {
                            DispatchQueue.main.async {
                                UIApplication.shared.keyWindow?.hideHud()
                                self.showError(error, showPleaseTryAgain: true, additionalMessage: "test")
                            }
                        }
                    }
                }
            }
        )
    }
}
