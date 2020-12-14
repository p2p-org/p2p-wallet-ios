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
    struct Response<T: Decodable>: Decodable {
        let success: Bool?
        let data: T?
    }
    
    struct ResponsePriceRecord: Decodable {
        let close: Double?
        let open: Double?
        let low: Double?
        let high: Double?
        let startTime: Double?
    }
    
    let endpoint = "https://serum-api.bonfida.com"
    
    func send<T: Decodable>(_ path: String, decodedTo: T.Type) -> Single<T> {
        request(.get, "\(endpoint)\(path)")
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData()
            .take(1)
            .asSingle()
            .map {try JSONDecoder().decode(T.self, from: $0.1)}
    }
    
    func getCurrentPrice(from: String, to: String) -> Single<CurrentPrice> {
        send("/candles/\(from)\(to)?limit=1&resolution=86400", decodedTo: Response<[ResponsePriceRecord]>.self)
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
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
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

extension Period {
    var resolution: UInt {
        switch self {
        case .day:
            return 60*60
        case .week, .month:
            return 60*60*24
        case .year:
            return 60*60*24*30
        case .all:
            return 60*60*24*30*12
        }
    }
    
    var limit: UInt? {
        switch self {
        case .day:
            return 24
        case .week:
            return 7
        case .month:
            return 30
        case .year:
            return 12
        case .all:
            return nil
        }
    }
}
