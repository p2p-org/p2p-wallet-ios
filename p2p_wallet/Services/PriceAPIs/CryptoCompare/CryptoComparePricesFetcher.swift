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
    let apikey = "ad6104e4e9d655c1faab7ef1743c16651a1628f01d384bc5fea09661c0eb18db"
    
    func getCurrentPrices(coins: [String], toFiat fiat: String) -> Single<[String: CurrentPrice?]> {
        var path = "/pricemulti?"
        path += "api_key=\(apikey)&"
        return send("\(path)fsyms=\(coins.joined(separator: ","))&tsyms=\(fiat)", decodedTo: [String: [String: Double]].self)
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
    
    func getHistoricalPrice(of coinName: String, fiat: String, period: Period) -> Single<[PriceRecord]> {
        var path = "/v2"
        switch period {
        case .last1h:
            path += "/histominute?limit=60"
        case .last4h:
            path += "/histominute?limit=240" // 60*4
        case .day:
            path += "/histohour?limit=24"
        case .week:
            path += "/histoday?limit=7"
        case .month:
            path += "/histoday?limit=30"
        }
        path += "&"
        path += "api_key=\(apikey)&"
        return send("\(path)fsym=\(coinName)&tsym=\(fiat)", decodedTo: Response.self)
            .map {$0.Data.Data}
            .map {
                $0.map {
                    PriceRecord(
                        close: $0.close,
                        open: $0.open,
                        low: $0.low,
                        high: $0.high,
                        startTime: Date(timeIntervalSince1970: TimeInterval($0.time))
                    )
                }
            }
    }
}
