//
//  CreateWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class CreateOrRestoreWalletVC: IntroVCWithButtons {
    override var index: Int {1}
    
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
                    let nc = BENavigationController(rootViewController: PhrasesVC())
                    UIApplication.shared.changeRootVC(to: nc)
                }
            }
        )
    }
    
    @objc func buttonRestoreWalletDidTouch() {
        let alertController = UIAlertController(title: L10n.securityKeys.uppercaseFirst, message: L10n.enterSecurityKeys, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = L10n.securityKeys.uppercaseFirst
        }
        let confirmAction = UIAlertAction(title: L10n.ok, style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let text = alertController.textFields?.first?.text else { return }
            do {
                let phrases = text.components(separatedBy: " ")
                _ = try Mnemonic(phrase: phrases.filter {!$0.isEmpty})
                let nc = BENavigationController(rootViewController: WelcomeBackVC(phrases: phrases))
                UIApplication.shared.changeRootVC(to: nc)
            } catch {
                self.showError(error)
            }
        }
        alertController.addAction(confirmAction)
        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
