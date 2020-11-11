//
//  WalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation

class WalletVM: ListViewModel<String> {
    let balanceVM = BalancesVM.ofCurrentUser
}
