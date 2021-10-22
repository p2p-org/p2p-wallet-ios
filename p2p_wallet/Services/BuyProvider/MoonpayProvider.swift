//
// Created by Giang Long Tran on 21.10.21.
//

import Foundation
import CryptoKit

public struct MoonpayProvider: BuyProvider {
    public enum Environment {
        case staging
        case production
    }

    let environment: Environment
    let apiKey: String
    let showOnlyCurrencies: String?
    let defaultCurrencyCode: String?
    let walletAddress: String?
    let walletAddresses: String?

    public init(
            environment: Environment,
            apiKey: String,
            showOnlyCurrencies: String?,
            defaultCurrencyCode: String?,
            walletAddress: String?,
            walletAddresses: String?
    ) {
        self.environment = environment
        self.apiKey = apiKey
        self.showOnlyCurrencies = showOnlyCurrencies
        self.defaultCurrencyCode = defaultCurrencyCode
        self.walletAddress = walletAddress
        self.walletAddresses = walletAddresses
    }

    public func getUrl() -> String {
        let params: BuyProviderUtils.Params = [
            "apiKey": apiKey,
            "showOnlyCurrencies": showOnlyCurrencies,
            "defaultCurrencyCode": defaultCurrencyCode,
            "walletAddress": walletAddress,
            "walletAddresses": walletAddresses,
        ]

        let paramStr = params.query
        let originalUrl = environment.endpoint + "?" + paramStr;

        return originalUrl + "&signature=\(sign(originalUrl: originalUrl))"
    }

    private func sign(originalUrl: String) -> String {
        hmacWithSHA256(message: originalUrl, with: apiKey)
    }
}

extension MoonpayProvider.Environment {
    var endpoint: String {
        switch self {
        case .staging:
            return "https://buy-staging.moonpay.com"
        case .production:
            return "https://buy.moonpay.com"
        }
    }
}

func hmacWithSHA256(message: String, with key: String) -> String {
    let keyData = SymmetricKey(data: key.data(using: .utf8)!)
    let messageData = message.data(using: .utf8)!

    let signature = HMAC<SHA256>.authenticationCode(for: messageData, using: keyData)
    return Data(signature).base64urlEncodedString()
}