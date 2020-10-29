//
//  CreateWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class CreateWalletVC: IntroVC {
    override var index: Int {1}
    
    lazy var createWalletButton = WLButton.stepButton(type: .main, label: L10n.createNewWallet.uppercaseFirst)
    lazy var restoreWalletButton = WLButton.stepButton(type: .sub, label: L10n.iVeAlreadyHadAWallet.uppercaseFirst)
    
    override func setUp() {
        super.setUp()
        descriptionLabel.isHidden = true
        
        stackView.constraintToSuperviewWithAttribute(.centerY)?.isActive = false
        stackView.autoPinEdge(toSuperviewSafeArea: .top)
        stackView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 16)
        
        let topSpacingView = UIView(forAutoLayout: ())
        topSpacingView.heightAnchor.constraint(lessThanOrEqualToConstant: 100)
            .isActive = true
        
        stackView.insertArrangedSubview(topSpacingView, at: 0)
        stackView.addArrangedSubview(UIView(forAutoLayout: ()))
        
        let buttonStackView: UIStackView = {
            let stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
            stackView.addArrangedSubview(createWalletButton)
            stackView.addArrangedSubview(restoreWalletButton)
            return stackView
        }()
        
        stackView.addArrangedSubview(buttonStackView)
        buttonStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60)
            .isActive = true
        
    }
}
