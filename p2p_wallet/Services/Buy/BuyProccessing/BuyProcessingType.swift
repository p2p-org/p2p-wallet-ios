//
// Created by Giang Long Tran on 21.10.21.
//

import Foundation

protocol BuyProcessingType {
    func getUrl() -> String
}

protocol BuyCurrencyType {}

protocol BuyProviderFactory {
    func create(
        walletRepository: WalletsRepository,
        crypto: Buy.CryptoCurrency,
        initialAmount: Double,
        currency: Buy.FiatCurrency
    ) throws -> BuyProcessingType
}

extension Buy {
    class MoonpayFactory: BuyProviderFactory {
        func create(walletRepository: WalletsRepository, crypto: CryptoCurrency, initialAmount: Double, currency: FiatCurrency) throws -> BuyProcessingType {
//            guard let walletAddress = walletRepository.getWallets().first(where: { $0.token.symbol == crypto.toWallet() })?.pubkey else {
//                throw SolanaSDK.Error.other(L10n.thereIsNoWalletInYourAccount("ETH"))
//            }
            
            return MoonpayBuyProcessing(
                environment: Defaults.apiEndPoint.network == .mainnetBeta ?
                    .production :
                    .staging,
                apiKey: Defaults.apiEndPoint.network == .mainnetBeta ?
                    .secretConfig("MOONPAY_PRODUCTION_API_KEY")! :
                    .secretConfig("MOONPAY_STAGING_API_KEY")!,
                currencyCode: crypto.rawValue,
                walletAddress: walletRepository.nativeWallet?.pubkey,
                baseCurrencyCode: currency.rawValue,
                baseCurrencyAmount: initialAmount
            )
        }
    }
}
