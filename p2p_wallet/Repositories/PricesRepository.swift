//
//  PricesRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import Foundation
import RxSwift

protocol PricesRepository {
    func currentPrice(for coinName: String) -> CurrentPrice?
    func pricesObservable() -> Observable<[String: CurrentPrice]>
    func observePrice(of coinName: String) -> Observable<CurrentPrice?>
    func fetchHistoricalPrice(for coinName: String, period: Period) -> Single<[PriceRecord]>
    func fetchAllTokensPrice()
    func getCurrentPrices() -> [String: CurrentPrice]
}

extension PricesManager: PricesRepository {
    func getCurrentPrices() -> [String: CurrentPrice] {
        currentPrices.value
    }
    
    func pricesObservable() -> Observable<[String: CurrentPrice]> {
        currentPrices.asObservable()
    }
    
    func observePrice(of coinName: String) -> Observable<CurrentPrice?> {
        pricesObservable()
            .map {[weak self] _ in self?.currentPrice(for: coinName)}
    }
    
    var solPrice: CurrentPrice? {
        currentPrice(for: "SOL")
    }
}
