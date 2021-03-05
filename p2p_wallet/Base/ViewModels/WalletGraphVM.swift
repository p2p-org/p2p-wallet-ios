//
//  WalletGraphVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation
import RxSwift

class WalletGraphVM: BaseVM<[PriceRecord]> {
    let symbol: String
    var period: Period = .last1h
    
    init(symbol: String) {
        self.symbol = symbol
        super.init(initialData: [])
    }
    
    override var request: Single<[PriceRecord]> {
        PricesManager.shared.fetchHistoricalPrice(for: symbol, period: period)
    }
    
    override func shouldReload() -> Bool {
        // always allow
        true
    }
}
