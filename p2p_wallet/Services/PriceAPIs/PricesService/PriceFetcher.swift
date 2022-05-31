//
//  PriceFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

protocol PricesFetcher {
    var endpoint: String { get }
    func getCurrentPrices(coins: [String], toFiat fiat: String) -> Single<[String: CurrentPrice?]>
    func getHistoricalPrice(of coinName: String, fiat: String, period: Period) -> Single<[PriceRecord]>
    func getValueInUSD(fiat: String) -> Single<Double?>
}

extension PricesFetcher {
    func send<T: Decodable>(_ path: String, decodedTo _: T.Type) -> Single<T> {
        Single.async {
            let (data, response) = try await URLSession.shared.data(from: .init(string: "\(endpoint)\(path)")!)
            guard let response = response as? HTTPURLResponse else { throw SolanaError.unknown }
            switch response.statusCode {
            case 200 ... 299:
                return try JSONDecoder().decode(T.self, from: data)
            default:
                throw SolanaError.other("Invalid status code") // TODO: - Fix later
            }
        }
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
