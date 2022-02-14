//
// Created by Giang Long Tran on 21.10.21.
//

import Foundation

public struct TransakProccessingProvider: Buy.ProcessingService {
    public enum Environment {
        case staging
        case production
    }

    let environment: Environment

    let networks: [String]
    let cryptoCurrencies: String
    let themeColor: String
    let hostURL: String?
    let apiKey: String
    let defaultCryptoCurrency: String?
    let walletAddress: String?
    let walletAddressesData: String?
    let disableWalletAddressForm: String
    let hideMenu: String

    let extraParams: BuyProviderUtils.Params = [:]

    public init(environment: Environment,
                networks: [String],
                cryptoCurrencies: String,
                themeColor: String = "5887FF",
                hostURL: String?, apiKey: String,
                defaultCryptoCurrency: String?,
                walletAddress: String?,
                walletAddressesData: String?,
                disableWalletAddressForm: String = "true",
                hideMenu: String = "true"
    ) {
        self.environment = environment
        self.networks = networks
        self.cryptoCurrencies = cryptoCurrencies
        self.themeColor = themeColor
        self.hostURL = hostURL
        self.apiKey = apiKey
        self.defaultCryptoCurrency = defaultCryptoCurrency
        self.walletAddress = walletAddress
        self.walletAddressesData = walletAddressesData
        self.disableWalletAddressForm = disableWalletAddressForm
        self.hideMenu = hideMenu
    }

    public func getUrl() -> String {
        let params: BuyProviderUtils.Params = [
            "networks": networks.joined(separator: ","),
            "cryptoCurrencyList": cryptoCurrencies,
            "themeColor": themeColor,
            "hostURL": hostURL,
            "apiKey": apiKey,
            "defaultCryptoCurrency": defaultCryptoCurrency,
            "walletAddress": walletAddress,
            "walletAddressesData": walletAddressesData,
            "disableWalletAddressForm": disableWalletAddressForm,
            "hideMenu": hideMenu
        ]

        let paramStr = params.merging(extraParams, uniquingKeysWith: { $1 }).query
        return environment.endpoint + "?" + paramStr
    }
}

extension TransakProccessingProvider.Environment {
    var endpoint: String {
        switch self {
        case .staging:
            return "https://staging-global.transak.com"
        case .production:
            return "https://global.transak.com"
        }
    }
}
