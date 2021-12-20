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
        
        static func fromEnvironment() -> API {
            let endpoint = "https://api.moonpay.com/v3"
            if Defaults.apiEndPoint.network == .mainnetBeta {
                return API(endpoint: endpoint, apiKey: .secretConfig("MOONPAY_PRODUCTION_API_KEY")!)
            } else {
                return API(endpoint: endpoint, apiKey: .secretConfig("MOONPAY_STAGING_API_KEY")!)
            }
        }
    }
}