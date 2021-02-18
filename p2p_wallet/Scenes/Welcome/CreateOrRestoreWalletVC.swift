//
//  CreateWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class CreateOrRestoreWalletVC: WLIntroVC {
    lazy var createWalletButton = WLButton.stepButton(type: .blue, label: L10n.createNewWallet.uppercaseFirst)
        .onTap(self, action: #selector(buttonCreateWalletDidTouch))
    lazy var restoreWalletButton = WLButton.stepButton(type: .sub, label: L10n.iVeAlreadyHadAWallet.uppercaseFirst)
        .onTap(self, action: #selector(buttonRestoreWalletDidTouch))
    
    override func setUp() {
        super.setUp()
        
        buttonsStackView.addArrangedSubview(createWalletButton)
        buttonsStackView.addArrangedSubview(restoreWalletButton)
    }
    
    // MARK: - Actions
    @objc func buttonCreateWalletDidTouch() {
        let vc = TermsAndConditionsVC()
        vc.completion = {
            let vc = DependencyContainer.shared.makeCreatePhrasesVC()
            let nc = BENavigationController(rootViewController: vc)
            nc.isModalInPresentation = true
            self.parent?.present(nc, animated: true, completion: nil)
        }
        
        parent?.present(vc, animated: true, completion: nil)
    }
    
    @objc func buttonRestoreWalletDidTouch() {
        let vc = DependencyContainer.shared.makeRestoreWalletVC()
        parent?.show(vc, sender: nil)
    }
}
