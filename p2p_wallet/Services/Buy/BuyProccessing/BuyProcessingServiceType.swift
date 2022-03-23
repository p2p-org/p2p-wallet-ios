//
// Created by Giang Long Tran on 21.10.21.
//

import Foundation

protocol BuyProcessingServiceType {
    func getUrl() -> String
}

protocol BuyProcessingFactory {
    func create(
        walletRepository: WalletsRepository,
        crypto: Buy.CryptoCurrency,
        initialAmount: Double,
        currency: Buy.FiatCurrency
    ) throws -> BuyProcessingServiceType
}

extension Buy {
    class MoonpayBuyProcessingFactory: BuyProcessingFactory {
        func create(
            walletRepository: WalletsRepository,
            crypto: CryptoCurrency,
            initialAmount: Double,
            currency: FiatCurrency
        ) throws -> BuyProcessingServiceType {
//            guard let walletAddress = walletRepository.getWallets().first(where: { $0.token.symbol == crypto.toWallet() })?.pubkey else {
//                throw SolanaSDK.Error.other(L10n.thereIsNoWalletInYourAccount("ETH"))
//            }

            MoonpayBuyProcessing(
                environment: Defaults.apiEndPoint.network == .mainnetBeta ?
                    .production :
                    .staging,
                apiKey: Defaults.apiEndPoint.network == .mainnetBeta ?
                    .secretConfig("MOONPAY_PRODUCTION_API_KEY")! :
                    .secretConfig("MOONPAY_STAGING_API_KEY")!,
                currencyCode: crypto.moonpayCode,
                walletAddress: walletRepository.nativeWallet?.pubkey,
                baseCurrencyCode: currency.moonpayCode,
                baseCurrencyAmount: initialAmount
            )
        }
    }
}
