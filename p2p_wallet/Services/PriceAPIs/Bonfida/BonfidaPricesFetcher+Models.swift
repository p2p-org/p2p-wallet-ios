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
