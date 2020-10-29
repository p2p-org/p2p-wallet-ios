//
//  ConfirmPinCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class ConfirmPinCodeVC: PinCodeVC {
    let currentPinCode: String
    init(currentPinCode: String) {
        self.currentPinCode = currentPinCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
