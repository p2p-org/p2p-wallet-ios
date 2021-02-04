//
//  WalletGraphVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation
import RxSwift

class WalletGraphVM: BaseVM<[PriceRecord]> {
    let wallet: Wallet
    var period: Period = .last1h
    
    init(wallet: Wallet) {
        self.wallet = wallet
        super.init(initialData: [])
    }
    
    override var request: Single<[PriceRecord]> {
        PricesManager.shared.fetchHistoricalPrice(for: wallet.symbol, period: period)
    }
    
    override func shouldReload() -> Bool {
        // always allow
        true
    }
}
