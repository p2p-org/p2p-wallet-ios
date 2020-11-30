//
//  ConfirmPinCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class ConfirmPinCodeVC: PinCodeVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.normal(translucent: true)}
    
    let currentPinCode: String
    init(currentPinCode: String) {
        self.currentPinCode = currentPinCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        label.text = L10n.confirmPINCode.uppercaseFirst
    }
    
    override func buttonNextDidTouch() {
        if pinCodeTextField.text.value != currentPinCode {
            showAlert(title: L10n.error, message: L10n.passcodesDoNotMatch)
            return
        }
        AccountStorage.shared.save(currentPinCode)
        completion?(currentPinCode)
    }
}
