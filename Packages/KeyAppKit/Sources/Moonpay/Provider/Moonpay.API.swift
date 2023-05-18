//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation

public extension Moonpay {
    struct API {
        public struct ErrorResponse: Codable {
            let message: String
            let type: String
        }

        public let endpoint: String
        public let apiKey: String
        
        public init(endpoint: String, apiKey: String) {
            self.endpoint = endpoint
            self.apiKey = apiKey
        }
    }

    enum Kind {
        case client
        case server
    }
}
