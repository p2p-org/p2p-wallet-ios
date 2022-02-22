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
    let baseCurrencyCode: String?
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
        baseCurrencyCode: String? = nil,
        baseCurrencyAmount: Double? = nil,
        quoteCurrencyAmount: Double? = nil) {
        self.environment = environment
        self.apiKey = apiKey
        self.showOnlyCurrencies = showOnlyCurrencies
        self.currencyCode = currencyCode
        self.defaultCurrencyCode = defaultCurrencyCode
        self.walletAddress = walletAddress
        self.walletAddresses = walletAddresses
        self.baseCurrencyCode = baseCurrencyCode
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
            "baseCurrencyCode": baseCurrencyCode,
            "baseCurrencyAmount": baseCurrencyAmount != nil ? "\(baseCurrencyAmount!)" : nil,
            "quoteCurrencyAmount": quoteCurrencyAmount != nil ? "\(quoteCurrencyAmount!)" : nil
        ]
    
        let path = environment.endpoint + "?" + params.query
        debugPrint(path)
        
        return path
    }
}

extension MoonpayProvider.Environment {
    var endpoint: String { "https://moonpay.wallet.p2p.org/" }
}
