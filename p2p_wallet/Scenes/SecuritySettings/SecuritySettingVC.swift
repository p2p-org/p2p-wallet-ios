//
//  SecuritySettingVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class SecuritySettingVC: WLIntroVC {
    var nextVC: UIViewController {
        fatalError("Must override")
    }
    
    lazy var acceptButton = WLButton.stepButton(type: .blue, label: nil)
        .onTap(self, action: #selector(buttonAcceptDidTouch))
    
    lazy var doThisLaterButton = WLButton.stepButton(type: .sub, label: L10n.doThisLater)
        .onTap(self, action: #selector(buttonDoThisLaterDidTouch))
    
    override func setUp() {
        super.setUp()
        
        buttonsStackView.addArrangedSubview(acceptButton)
        buttonsStackView.addArrangedSubview(doThisLaterButton)
    }
    
    @objc func buttonDoThisLaterDidTouch() {
        next()
    }
    
    @objc func buttonAcceptDidTouch() {}
    
    func next() {
        show(nextVC, sender: nil)
    }
}
