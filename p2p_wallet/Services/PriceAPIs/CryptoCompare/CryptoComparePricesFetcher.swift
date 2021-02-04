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
    let apikey = "887b4e547fd87338984f7298d0b25dffee49522df82c0b4ed0a301be9ca688c9"
    
    func getCurrentPrices(coins: [String], toFiat fiat: String) -> Single<[String: CurrentPrice?]> {
        send("/pricemulti?api_key=\(apikey)&fsyms=\(coins.joined(separator: ","))&tsyms=\(fiat)", decodedTo: [String: [String: Double]].self)
            .map {dict in
                var result = [String: CurrentPrice?]()
                for key in dict.keys {
                    var price: CurrentPrice?
                    if let value = dict[key]?[fiat] {
                        price = CurrentPrice(value: value)
                    }
                    result[key] = price
                }
                return result
            }
    }
    
    func getHistoricalPrice(of coinName: String, period: Period) -> Single<[PriceRecord]> {
        .just([])
    }
}
