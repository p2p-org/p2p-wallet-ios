//
//  WalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift

class WalletVM: ListViewModel<SolanaSDK.Token> {
    let balanceVM = BalancesVM.ofCurrentUser
    static var ofCurrentUser = WalletVM()
    
    override func reload() {
        super.reload()
        balanceVM.reload()
    }
    
    override var request: Single<[SolanaSDK.Token]> {
        SolanaSDK.shared.getProgramAccounts(in: SolanaSDK.cluster)
    }
}
