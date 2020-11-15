//
//  WelcomeBackVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class WelcomeBackVC: IntroVCWithButtons {
    lazy var goToWalletButton = WLButton.stepButton(type: .main, label: L10n.goToWallet)
        .onTap(self, action: #selector(buttonGoToWalletDidTouch))
    
    let phrases: [String]
    init(phrases: [String]) {
        self.phrases = phrases
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        descriptionLabel.isHidden = true
        titleLabel.text = L10n.welcomeBackToTheWowletSpace
        
        buttonStackView.addArrangedSubview(goToWalletButton)
    }
    
    @objc func buttonGoToWalletDidTouch() {
        UIApplication.shared.showIndetermineHudWithMessage(L10n.restoringWallet)
        DispatchQueue.global().async {
            do {
                let account = try SolanaSDK.Account(phrase: self.phrases, network: SolanaSDK.network)
                try KeychainStorage.shared.save(account)
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    UIApplication.shared.changeRootVC(to: SSPinCodeVC(), withNaviationController: true)
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
