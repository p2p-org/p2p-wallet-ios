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
    var period: Period = .day
    
    init(wallet: Wallet) {
        self.wallet = wallet
        super.init(initialData: [])
    }
    
    override var request: Single<[PriceRecord]> {
        if wallet.symbol.contains("USD") {
            return .just([
                PriceRecord(close: 1, open: 1, low: 1, high: 1, startTime: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
                PriceRecord(close: 1, open: 1, low: 1, high: 1, startTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
                PriceRecord(close: 1, open: 1, low: 1, high: 1, startTime: Date())
            ])
        }
        return PricesManager.shared.fetchHistoricalPrice(for: wallet.symbol, period: period)
    }
    
    override func shouldReload() -> Bool {
        // always allow
        true
    }
}
