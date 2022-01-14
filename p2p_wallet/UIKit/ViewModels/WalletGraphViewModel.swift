//
//  WalletGraphViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation
import RxSwift
import BECollectionView

class WalletGraphViewModel: BEListViewModel<PriceRecord> {
    let symbol: String
    @Injected private var pricesService: PricesServiceType
    var period: Period = .last1h
    
    init(symbol: String) {
        self.symbol = symbol
        super.init()
    }
    
    override func createRequest() -> Single<[PriceRecord]> {
        pricesService.fetchHistoricalPrice(for: symbol, period: period)
    }
}
