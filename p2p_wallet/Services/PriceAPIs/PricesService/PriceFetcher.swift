//
//  PriceFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxAlamofire
import RxCocoa
import RxSwift

protocol PricesFetcher {
    var endpoint: String { get }
    func getCurrentPrices(coins: [String], toFiat fiat: String) -> Single<[String: CurrentPrice?]>
    func getHistoricalPrice(of coinName: String, fiat: String, period: Period) -> Single<[PriceRecord]>
    func getValueInUSD(fiat: String) -> Single<Double?>
}

extension PricesFetcher {
    func send<T: Decodable>(_ path: String, decodedTo _: T.Type) -> Single<T> {
        request(.get, "\(endpoint)\(path)")
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .validate(statusCode: 200 ..< 300)
            .validate(contentType: ["application/json"])
            .responseData()
            .take(1)
            .asSingle()
            .map { try JSONDecoder().decode(T.self, from: $0.1) }
    }
}

struct CurrentPrice: Codable, Hashable {
    struct Change24h: Codable, Hashable {
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

    func converting(exchangeRate: Double) -> PriceRecord {
        PriceRecord(
            close: close * exchangeRate,
            open: open * exchangeRate,
            low: low * exchangeRate,
            high: high * exchangeRate,
            startTime: startTime
        )
    }
}

enum Period: String, CaseIterable {
    case last1h
    case last4h
    case day
    case week
    case month
//    case year
//    case all
}
