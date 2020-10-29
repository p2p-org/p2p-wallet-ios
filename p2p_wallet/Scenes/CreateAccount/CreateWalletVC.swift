//
//  CreateWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class CreateWalletVC: IntroVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    // MARK: - Properties
    let account: SolanaSDK.Account
    
    // MARK: - Subviews
    lazy var backUpButton = WLButton.stepButton(type: .main, label: L10n.backup)
        .onTap(self, action: #selector(buttonBackUpDidTouch))
    
    // MARK: - Initializers
    init(account: SolanaSDK.Account) {
        self.account = account
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        titleLabel.text = L10n.congratulations
        descriptionLabel.text = L10n.yourWalletHasBeenSuccessfullyCreated
        
        buttonStackView.addArrangedSubview(backUpButton)
    }
    
    // MARK: - Actions
    @objc func buttonBackUpDidTouch() {
        let vc = PhrasesVC(account: account)
        show(vc, sender: nil)
    }
}
