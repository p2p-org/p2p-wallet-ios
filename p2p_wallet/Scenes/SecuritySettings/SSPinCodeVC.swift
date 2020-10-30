//
//  SSPinCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class SSPinCodeVC: PinCodeVC {
    init() {
        super.init(nibName: nil, bundle: nil)
        completion = { _ in
            UIApplication.shared.changeRootVC(to: EnableBiometryVC(), withNaviationController: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
