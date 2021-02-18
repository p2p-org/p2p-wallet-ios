//
//  SSPinCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class SSPinCodeVC: CreatePassCodeVC {
    override init(accountStorage: KeychainAccountStorage) {
        super.init(accountStorage: accountStorage)
        completion = { _ in
            UIApplication.shared.changeRootVC(to: EnableBiometryVC(), withNaviationController: true)
        }
    }
}
