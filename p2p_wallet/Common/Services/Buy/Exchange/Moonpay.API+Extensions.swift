//
//  Moonpay.API+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2022.
//

import Foundation
import Moonpay

extension Moonpay.API {
    static func fromEnvironment(kind: Moonpay.Kind = .client) -> Self {
        let endpoint: String
        let apiKey: String
        switch kind {
        case .client:
            endpoint = "https://api.moonpay.com/"
            apiKey = .secretConfig("MOONPAY_PRODUCTION_API_KEY")!
        case .server:
            switch Defaults.moonpayEnvironment {
            case .production:
                endpoint = .secretConfig("MOONPAY_PRODUCTION_SELL_ENDPOINT")!
                apiKey = .secretConfig("MOONPAY_PRODUCTION_API_KEY")!
            case .sandbox:
                endpoint = .secretConfig("MOONPAY_STAGING_SELL_ENDPOINT")!
                apiKey = .secretConfig("MOONPAY_STAGING_API_KEY")!
            }
        }
        return .init(endpoint: endpoint, apiKey: apiKey)
    }
}
