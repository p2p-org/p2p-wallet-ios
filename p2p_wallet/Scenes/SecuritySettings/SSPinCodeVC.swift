//
//  SSPinCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class SSPinCodeVC: CreatePassCodeVC {
    init(accountStorage: KeychainAccountStorage, rootViewModel: RootViewModel) {
        super.init(accountStorage: accountStorage)
        completion = { _ in
            rootViewModel.navigationSubject.accept(.settings(.biometry))
        }
    }
    
}
