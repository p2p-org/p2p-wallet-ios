//
//  CryptoComparePricesFetcher+Models.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/02/2021.
//

import Foundation

extension CryptoComparePricesFetcher {
    struct Response: Decodable {
//        "Response": "Success",
//        "Message": "",
//        "HasWarning": false,
//        "Type": 100,
//        "RateLimit": {},
        let Data: ResponseData
    }

    struct ResponseData: Decodable {
//        "Aggregated": false,
//        "TimeFrom": 1611532800,
//        "TimeTo": 1612396800,
        let Data: [ResponseDataData]
    }

    struct ResponseDataData: Decodable {
//        "high": 34881.18,
//        "low": 31937.09,
//        "open": 32283.66,
//        "volumefrom": 59529.49,
//        "volumeto": 1989618039.07,
//        "conversionType": "direct",
//        "conversionSymbol": ""
        let time: UInt64
        let close: Double
        let high: Double
        let low: Double
        let open: Double
    }
}
