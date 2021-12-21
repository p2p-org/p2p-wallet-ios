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
    
    // Properties
    let environment: Environment
    let apiKey: String
    let showOnlyCurrencies: String?
    let currencyCode: String?
    let defaultCurrencyCode: String?
    let walletAddress: String?
    
    let walletAddresses: String?
    let baseCurrencyAmount: Double?
    let quoteCurrencyAmount: Double?
    
    public init(
        environment: Environment,
        apiKey: String,
        showOnlyCurrencies: String? = nil,
        currencyCode: String? = nil,
        defaultCurrencyCode: String? = nil,
        walletAddress: String? = nil,
        walletAddresses: String? = nil,
        baseCurrencyAmount: Double? = nil,
        quoteCurrencyAmount: Double? = nil) {
        self.environment = environment
        self.apiKey = apiKey
        self.showOnlyCurrencies = showOnlyCurrencies
        self.currencyCode = currencyCode
        self.defaultCurrencyCode = defaultCurrencyCode
        self.walletAddress = walletAddress
        self.walletAddresses = walletAddresses
        self.baseCurrencyAmount = baseCurrencyAmount
        self.quoteCurrencyAmount = quoteCurrencyAmount
    }
    
    public func getUrl() -> String {
        let params: BuyProviderUtils.Params = [
            "apiKey": apiKey,
            "showOnlyCurrencies": showOnlyCurrencies,
            "defaultCurrencyCode": defaultCurrencyCode,
            "currencyCode": currencyCode,
            "walletAddress": walletAddress,
            "walletAddresses": walletAddresses,
            "baseCurrencyAmount": baseCurrencyAmount != nil ? "\(baseCurrencyAmount!)" : nil,
            "quoteCurrencyAmount": quoteCurrencyAmount != nil ? "\(quoteCurrencyAmount!)" : nil
        ]
        
        let paramStr = params.query
        let originalUrl = environment.endpoint + "?" + paramStr
        
        debugPrint(originalUrl + "&signature=\(sign(originalUrl: originalUrl))")
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

private func hmacWithSHA256(message: String, with key: String) -> String {
    let keyData = SymmetricKey(data: key.data(using: .utf8)!)
    let messageData = message.data(using: .utf8)!
    
    let signature = HMAC<SHA256>.authenticationCode(for: messageData, using: keyData)
    return Data(signature).base64urlEncodedString()
}
