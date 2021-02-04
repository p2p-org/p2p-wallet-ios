//
//  BonfidaPricesFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxCocoa
import RxAlamofire
import RxSwift

struct BonfidaPricesFetcher: PricesFetcher {
    let endpoint = "https://serum-api.bonfida.com"
    
    func getCurrentPrices(coins: [String], toFiat fiat: String) -> Single<[CurrentPrice]> {
        // WARNING: - ignored fiat, use USDT as fiat
        Single.zip(
            coins
                .map { coin in
                    if ["USDT", "USDC", "WUSDC"].contains(coin) {
                        return .just(CurrentPrice(value: 1))
                    }
                    return send("/candles/\(coin)USDT?limit=1&resolution=86400", decodedTo: Response<[ResponsePriceRecord]>.self)
                        .map {
                            let open: Double = $0.data?.first?.open ?? 0
                            let close: Double = $0.data?.first?.close ?? 0
                            let change24h = close - open
                            let change24hInPercentages = change24h / (open == 0 ? 1: open)
                            return CurrentPrice(
                                value: close,
                                change24h: CurrentPrice.Change24h(
                                    value: change24h,
                                    percentage: change24hInPercentages
                                )
                            )
                        }
                }
        )
    }
    
    func getHistoricalPrice(of coinName: String, period: Period) -> Single<[PriceRecord]> {
        var path = "/candles/\(coinName)USDT"
        
        if let limit = period.limit {
            path += "?limit=\(limit)&"
        } else {
            path += "?"
        }
        
        path += "resolution=\(period.resolution)"
        
        return send(path, decodedTo: Response<[ResponsePriceRecord]>.self)
            .map {$0.data ?? [ResponsePriceRecord]()}
            .map({ (records) -> [PriceRecord] in
                records.compactMap { record in
                    guard let close = record.close, let open = record.open, let low = record.low, let high = record.high, let startTime = record.startTime
                    else {return nil}
                    
                    return PriceRecord(close: close, open: open, low: low, high: high, startTime: Date(timeIntervalSince1970: startTime / 1000.0)
                    )
                }
            })
            .map {$0.reversed()}
    }
}

private extension Period {
    var resolution: UInt {
        switch self {
        case .last1h:
            return 60
        case .last4h:
            return 60
        case .day:
            return 60*60
        case .week, .month:
            return 60*60*24
//        case .year:
//            return 86400 // maximum resolution is 86400
//        case .all:
//            return 86400 // maximum resolution is 86400
        }
    }
    
    var limit: UInt? {
        switch self {
        case .last1h:
            return 60
        case .last4h:
            return 60*4
        case .day:
            return 24
        case .week:
            return 7
        case .month:
            return 30
//        case .year:
//            return 12 * 30
//        case .all:
//            return nil
        }
    }
}
