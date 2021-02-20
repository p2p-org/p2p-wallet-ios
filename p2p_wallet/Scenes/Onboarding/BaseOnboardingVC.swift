//
//  BaseOnboardingVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class BaseOnboardingVC: WLIntroVC {
    lazy var acceptButton = WLButton.stepButton(type: .blue, label: nil)
        .onTap(self, action: #selector(buttonAcceptDidTouch))
    lazy var doThisLaterButton = WLButton.stepButton(type: .sub, label: L10n.doThisLater)
        .onTap(self, action: #selector(buttonDoThisLaterDidTouch))
    
    override func setUp() {
        super.setUp()
        buttonsStackView.addArrangedSubviews([
            acceptButton,
            doThisLaterButton
        ])
    }
    
    @objc func buttonAcceptDidTouch() {
    }
    
    @objc func buttonDoThisLaterDidTouch() {
    }
}
