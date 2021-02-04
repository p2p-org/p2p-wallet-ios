//
//  BonfidaPricesFetcher+Models.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/02/2021.
//

import Foundation

extension BonfidaPricesFetcher {
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
}

extension Period {
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
