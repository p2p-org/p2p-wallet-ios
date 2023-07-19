//
// Created by Giang Long Tran on 21.10.21.
//

import Foundation
import KeyAppBusiness

protocol BuyProcessingServiceType {
    func getUrl() -> String
}

protocol BuyProcessingFactory {
    func create(
        walletRepository: SolanaAccountsService,
        fromCurrency: BuyCurrencyType,
        amount: Double,
        toCurrency: BuyCurrencyType,
        paymentMethod: String
    ) throws -> BuyProcessingServiceType
}

extension Buy {
    class MoonpayBuyProcessingFactory: BuyProcessingFactory {
        func create(
            walletRepository: SolanaAccountsService,
            fromCurrency: BuyCurrencyType,
            amount: Double,
            toCurrency: BuyCurrencyType,
            paymentMethod: String
        ) throws -> BuyProcessingServiceType {
            guard
                let from = fromCurrency as? MoonpayCodeMapping,
                let to = toCurrency as? MoonpayCodeMapping
            else {
                throw Buy.Exception.invalidInput
            }

            return MoonpayBuyProcessing(
                environment: Defaults.apiEndPoint.network == .mainnetBeta ?
                    .production :
                    .staging,
                apiKey: Defaults.apiEndPoint.network == .mainnetBeta ?
                    .secretConfig("MOONPAY_PRODUCTION_API_KEY")! :
                    .secretConfig("MOONPAY_STAGING_API_KEY")!,
                currencyCode: to.moonpayCode,
                walletAddress: walletRepository.nativeWallet?.pubkey,
                baseCurrencyCode: from.moonpayCode,
                baseCurrencyAmount: amount,
                paymentMethod: paymentMethod == "card" ? .creditDebitCard :
                    paymentMethod == "gbp_bank" ? .gbpBankTransfer :
                    .sepaBankTransfer
            )
        }
    }
}
