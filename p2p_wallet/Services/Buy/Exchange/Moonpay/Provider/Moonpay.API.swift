//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation

extension Moonpay {
    struct API {
        struct ErrorResponse: Codable {
            let message: String
            let type: String
        }

        let endpoint: String
        let apiKey: String

        static func fromEnvironment(kind: Kind = .client) -> API {
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
            return API(endpoint: endpoint, apiKey: apiKey)
        }
    }

    enum Kind {
        case client
        case server
    }
}
