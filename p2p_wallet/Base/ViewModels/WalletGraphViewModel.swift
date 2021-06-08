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
    let pricesRepository: PricesRepository
    var period: Period = .last1h
    
    init(symbol: String, pricesRepository: PricesRepository) {
        self.symbol = symbol
        self.pricesRepository = pricesRepository
        super.init()
    }
    
    override func createRequest() -> Single<[PriceRecord]> {
        pricesRepository.fetchHistoricalPrice(for: symbol, period: period)
    }
}
