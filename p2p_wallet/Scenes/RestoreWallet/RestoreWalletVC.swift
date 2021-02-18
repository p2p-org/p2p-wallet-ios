//
//  RestoreWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation
import SwiftUI

class RestoreWalletVC: WLIntroVC {
    lazy var iCloudRestoreButton = WLButton.stepButton(type: .black, label: " " + L10n.restoreUsingICloud)
        .onTap(self, action: #selector(buttonICloudRestoreDidTouch))
    lazy var restoreManuallyButton = WLButton.stepButton(type: .sub, label: L10n.restoreManually)
        .onTap(self, action: #selector(buttonRestoreManuallyDidTouch))
    
    let accountStorage: KeychainAccountStorage
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
    }
    
    override func setUp() {
        super.setUp()
        backButton.isHidden = false
        descriptionLabel.isHidden = false
        titleLabel.text = L10n.p2PWalletRecovery
        descriptionLabel.text = L10n.recoverYourP2PWalletManuallyOrUsingCloudServices
        
        buttonsStackView.addArrangedSubviews([
            iCloudRestoreButton,
            restoreManuallyButton
        ])
    }
    
    @objc func buttonICloudRestoreDidTouch() {
        guard let phrases = accountStorage.phrasesFromICloud() else
        {
            showAlert(title: L10n.noAccount, message: L10n.thereIsNoP2PWalletSavedInYourICloud)
            return
        }
        handlePhrases(phrases)
    }
    
    @objc func buttonRestoreManuallyDidTouch() {
        let vc = EnterPhrasesVC()
        let titleImageView = UIImageView(width: 24, height: 24, image: .securityKey, tintColor: .white)

        presentCustomModal(vc: vc, title: L10n.securityKeys.uppercaseFirst, titleImageView: titleImageView)
    }
    
    private func handlePhrases(_ text: String)
    {
        do {
            let phrases = text.components(separatedBy: " ")
            _ = try Mnemonic(phrase: phrases.filter {!$0.isEmpty})
            let vc = DependencyContainer.shared.makeWelcomeBackVC(phrases: phrases)
            let nc = BENavigationController(rootViewController: vc)
            UIApplication.shared.changeRootVC(to: nc)
        } catch {
            showError(error)
        }
    }
}
