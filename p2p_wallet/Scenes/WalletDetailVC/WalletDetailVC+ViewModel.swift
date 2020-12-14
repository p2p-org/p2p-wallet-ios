//
//  WalletDetailVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2020.
//

import Foundation
import RxSwift

extension WalletDetailVC {
    class ViewModel: WalletTransactionsVM {
        let graphVM: WalletGraphVM
        
        override init(wallet: Wallet) {
            graphVM = WalletGraphVM(wallet: wallet)
            super.init(wallet: wallet)
        }
        
        override func reload() {
            graphVM.reload()
            super.reload()
        }
    }
}
