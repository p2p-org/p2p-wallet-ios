//
//  PriceFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

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
    case day
    case week
    case month
//    case year
//    case all
    var shortString: String {
        var string = "1"
        switch self {
        case .day:
            string += "d"
        case .week:
            string += "w"
        case .month:
            string += "m"
        }
        return string
    }
}

protocol PricesFetcher {
    func getCurrentPrice(from: String, to: String) -> Single<CurrentPrice>
    func getHistoricalPrice(of coinName: String, period: Period) -> Single<[PriceRecord]>
}
