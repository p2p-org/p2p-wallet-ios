//
//  WalletGraphViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import BECollectionView
import Foundation
import RxSwift

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
