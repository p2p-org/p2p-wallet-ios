//
//  PinCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class PinCodeVC: BaseVStackVC {
    override var padding: UIEdgeInsets {
        var padding = super.padding
        padding.top += 78
        padding.left = 20
        padding.right = 20
        return padding
    }
    
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    lazy var pinCodeTextField: PinCodeTextField = {
        let tf = PinCodeTextField(forAutoLayout: ())
        tf.numberOfDigits = 6
        return tf
    }()
    
    override func setUp() {
        super.setUp()
        let label = UILabel(text: L10n.createAPINCodeToProtectYourWallet, textSize: 21, weight: .semibold, numberOfLines: 2, textAlignment: .center)
        
        stackView.spacing = 60
        stackView.alignment = .center
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(pinCodeTextField)
        
        pinCodeTextField.numberOfDigits = 6
    }
}
