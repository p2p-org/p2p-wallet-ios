//
//  CryptoComparePricesFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/02/2021.
//

import Foundation
import RxSwift

class CryptoComparePricesFetcher: PricesFetcher {
    let endpoint = "https://min-api.cryptocompare.com/data"
    
    func getCurrentPrices(coins: [String], toFiat fiat: String) -> Single<[CurrentPrice]> {
        send("/pricemulti?fsyms=\(coins.joined(separator: ","))&tsyms=\(fiat)", decodedTo: [String: [String: Double]].self)
            .map {dict in
                dict.keys.map {key in
                    return CurrentPrice(value: dict[key]?[fiat])
                }
            }
    }
    
    func getHistoricalPrice(of coinName: String, period: Period) -> Single<[PriceRecord]> {
        .just([])
    }
}
