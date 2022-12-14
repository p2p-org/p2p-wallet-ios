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
            switch kind {
            case .client:
                endpoint = "https://api.moonpay.com/"
            case .server:
                #if RELEASE
                endpoint = String.secretConfig("MOONPAY_PRODUCTION_SELL_ENDPOINT")!
                #else
                endpoint = String.secretConfig("MOONPAY_STAGING_SELL_ENDPOINT")!
                #endif
            }
            if Defaults.apiEndPoint.network == .mainnetBeta {
                return API(endpoint: endpoint, apiKey: .secretConfig("MOONPAY_PRODUCTION_API_KEY")!)
            } else {
                return API(endpoint: endpoint, apiKey: .secretConfig("MOONPAY_STAGING_API_KEY")!)
            }
        }
    }

    enum Kind {
        case client
        case server
    }
}
