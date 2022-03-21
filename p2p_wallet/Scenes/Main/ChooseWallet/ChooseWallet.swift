//
//  ChooseWallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import Foundation

protocol WalletDidSelectHandler {
    func walletDidSelect(_ wallet: Wallet)
}

enum ChooseWallet {}
