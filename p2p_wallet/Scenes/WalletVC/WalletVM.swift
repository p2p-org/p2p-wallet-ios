//
//  WalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift

class WalletVM: ListViewModel<String> {
    let balanceVM: BalancesVM
    
    override init() {
        BalancesVM.ofCurrentUser = BalancesVM()
        balanceVM = BalancesVM.ofCurrentUser
        super.init()
    }
    
    override func reload() {
        super.reload()
        balanceVM.reload()
    }
    
    override var request: Single<[String]> {
        SolanaSDK.shared.getProgramAccounts()
            .map {$0.map{$0.pubkey}}
    }
}
