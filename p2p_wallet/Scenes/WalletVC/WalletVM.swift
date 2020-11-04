//
//  WalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxCocoa

class BalancesVM {
    static let shared = BalancesVM()
    private init() {}
    let balance = BehaviorRelay<Double>(value: 0)
}

class WalletVM: ListViewModel<String> {
    let balanceVM = BalancesVM.shared
}
