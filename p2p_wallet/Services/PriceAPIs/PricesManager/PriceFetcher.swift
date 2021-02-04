//
//  PriceFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa
import RxAlamofire

protocol PricesFetcher {
    var endpoint: String {get}
    func getCurrentPrices(coins: [String], toFiat fiat: String) -> Single<[String: CurrentPrice?]>
    func getHistoricalPrice(of coinName: String, period: Period) -> Single<[PriceRecord]>
}

extension PricesFetcher {
    func send<T: Decodable>(_ path: String, decodedTo: T.Type) -> Single<T> {
        request(.get, "\(endpoint)\(path)")
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData()
            .take(1)
            .asSingle()
            .do(onSuccess: {response in
                Logger.log(message: String(data: response.1, encoding: .utf8) ?? "", event: .response, apiMethod: "getPrices")
            }, onSubscribe: {
                Logger.log(message: "\(endpoint)\(path)", event: .request, apiMethod: "getPrices")
            })
            .map {try JSONDecoder().decode(T.self, from: $0.1)}
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
    }
}

struct CurrentPrice: Hashable {
    struct Change24h: Hashable {
        var value: Double?
        var percentage: Double?
    }
    
    var value: Double?
    var change24h: Change24h?
}

struct PriceRecord: Hashable {
    let close: Double
    let open: Double
    let low: Double
    let high: Double
    let startTime: Date
}

enum Period: String, CaseIterable {
    case last1h
    case last4h
    case day
    case week
    case month
//    case year
//    case all
    var shortString: String {
        var string = ""
        switch self {
        case .last1h:
            string = "1h"
        case .last4h:
            string = "4h"
        case .day:
            string = "1d"
        case .week:
            string = "1w"
        case .month:
            string = "1m"
        }
        return string
    }
}
