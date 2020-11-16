//
//  PricesManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

struct PricesManager {
    var fetcher: PricesFetcher
    var prices: BehaviorRelay<[Price]> {fetcher.prices}
    
    init(fetcher: PricesFetcher) {
        self.fetcher = fetcher
    }
}
