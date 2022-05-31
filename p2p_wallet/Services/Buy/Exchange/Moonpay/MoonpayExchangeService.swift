//
// Created by Giang Long Tran on 21.02.2022.
//

import Foundation
import RxSwift

protocol MoonpayCodeMapping {
    var moonpayCode: String { get }
}

extension Buy {
    struct MoonpayExchange: Buy.ExchangeService {
        let provider: Moonpay.Provider

        init(provider: Moonpay.Provider) { self.provider = provider }

        func convert(input: ExchangeInput, to currency: Currency) -> Single<ExchangeOutput> {
            let currencies = [input.currency, currency]
            let base = currencies.first { $0 is FiatCurrency }
            let quote = currencies.first { $0 is CryptoCurrency }

            guard let base = base as? MoonpayCodeMapping, let quote = quote as? MoonpayCodeMapping
            else { return .error(Exception.invalidInput) }

            let baseAmount = input.currency is FiatCurrency ? input.amount : nil
            let quoteAmount = input.currency is CryptoCurrency ? input.amount : nil

            return Single.async {
                try await provider
                    .getBuyQuote(
                        baseCurrencyCode: base.moonpayCode,
                        quoteCurrencyCode: quote.moonpayCode,
                        baseCurrencyAmount: baseAmount,
                        quoteCurrencyAmount: quoteAmount
                    )
            }
            .map { quote in
                .init(
                    amount: currency is CryptoCurrency ? quote.quoteCurrencyAmount : quote.totalAmount,
                    currency: currency,
                    processingFee: quote.extraFeeAmount,
                    networkFee: quote.networkFeeAmount,
                    purchaseCost: quote.baseCurrencyAmount,
                    total: quote.totalAmount
                )
            }.catch { error in
                if let error = error as? Moonpay.Error {
                    switch error {
                    case let .message(message: message):
                        throw Exception.message(message)
                    }
                }
                throw error
            }
        }

        func getExchangeRate(
            from fiatCurrency: FiatCurrency,
            to cryptoCurrency: CryptoCurrency
        ) -> Single<ExchangeRate> {
            Single.async {
                try await provider
                    .getPrice(for: cryptoCurrency.moonpayCode, as: fiatCurrency.moonpayCode.uppercased())
            }
            .map { exchangeRate in
                .init(amount: exchangeRate, cryptoCurrency: cryptoCurrency, fiatCurrency: fiatCurrency)
            }
        }

        private func _getMinAmount(currencies: Moonpay.Currencies, for currency: Currency) -> Double {
            guard let currency = currency as? MoonpayCodeMapping else { return 0.0 }
            return currencies.first { e in e.code == currency.moonpayCode }?.minBuyAmount ?? 0.0
        }

        func getMinAmount(currency: Currency) -> Single<Double> {
            Single.async {
                try await provider
                    .getAllSupportedCurrencies()
            }
            .map { _getMinAmount(currencies: $0, for: currency) }
        }

        func getMinAmounts(_ currency1: Currency, _ currency2: Currency) -> Single<(Double, Double)> {
            Single.async {
                try await provider.getAllSupportedCurrencies()
            }
            .map { currencies in
                (
                    _getMinAmount(currencies: currencies, for: currency1),
                    _getMinAmount(currencies: currencies, for: currency2)
                )
            }
        }
    }
}

extension Buy.CryptoCurrency: MoonpayCodeMapping {
    var moonpayCode: String {
        switch self {
        case .eth:
            return "eth"
        case .sol:
            return "sol"
        case .usdc:
            return "usdc_sol"
        }
    }
}

extension Buy.FiatCurrency: MoonpayCodeMapping {
    var moonpayCode: String {
        switch self {
        case .usd:
            return "usd"
        }
    }
}
