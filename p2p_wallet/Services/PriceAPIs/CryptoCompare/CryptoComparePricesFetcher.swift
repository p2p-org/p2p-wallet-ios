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
    let apikey = String.secretConfig("CRYPTO_COMPARE_API_KEY")

    func getCurrentPrices(coins: [String], toFiat fiat: String) -> Single<[String: CurrentPrice?]> {
        var path = "/pricemulti?"
        if let apikey = apikey {
            path += "api_key=\(apikey)&"
        }

        let requests = coins
            .chunked(into: 30)
            .map { coins -> Single<[String: CurrentPrice?]> in
                let coinListQuery = coins
                    .joined(separator: ",")
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

                return self.send(
                    "\(path)fsyms=\(coinListQuery)&tsyms=\(fiat)",
                    decodedTo: [String: [String: Double]].self
                )
                    .map { dict in
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
                    .catchAndReturn([:])
            }

        return Single.zip(requests)
            .map { dictArray -> [String: CurrentPrice?] in
                let tupleArray: [(String, CurrentPrice?)] = dictArray.flatMap { $0 }
                let dictonary = Dictionary(tupleArray, uniquingKeysWith: { first, _ in first })
                return dictonary
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
        if let apikey = apikey {
            path += "api_key=\(apikey)&"
        }
        return send("\(path)fsym=\(coinName)&tsym=\(fiat)", decodedTo: Response.self)
            .map(\.Data.Data)
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

    func getValueInUSD(fiat: String) -> Single<Double?> {
        send("/price?fsym=USD&tsyms=\(fiat)", decodedTo: [String: Double].self)
            .map { $0[fiat] }
    }
}
