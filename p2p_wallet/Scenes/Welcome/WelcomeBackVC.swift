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
        .onTap(self, action: #selector(buttonGoToWalletDidTouch))
    
    let phrases: [String]
    let accountStorage: KeychainAccountStorage
    let rootViewModel: RootViewModel
    init(phrases: [String], accountStorage: KeychainAccountStorage, rootViewModel: RootViewModel) {
        self.phrases = phrases
        self.accountStorage = accountStorage
        self.rootViewModel = rootViewModel
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        
        // add center image
        var i = 3
        let logoImageView = UIImageView(width: 200, height: 200, image: .welcomeBack)
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
    
    @objc func buttonGoToWalletDidTouch() {
        UIApplication.shared.showIndetermineHudWithMessage(L10n.restoringWallet)
        DispatchQueue.global().async {
            do {
                let account = try SolanaSDK.Account(phrase: self.phrases, network: Defaults.network)
                try self.accountStorage.save(account)
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    self.rootViewModel.navigationSubject.accept(.settings(.pincode))
                }
            } catch {
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    self.showError(error)
                }
            }
        }
    }
}
