//
// Created by Giang Long Tran on 21.02.2022.
//

import Foundation

protocol MoonpayCodeMapping {
    var moonpayCode: String { get }
}

extension Buy {
    struct MoonpayExchange: Buy.ExchangeService {
        let provider: Moonpay.Provider

        init(provider: Moonpay.Provider) { self.provider = provider }

        func convert(input: ExchangeInput, to currency: Currency) async throws -> ExchangeOutput {
            let currencies = [input.currency, currency]
            let base = currencies.first { $0 is FiatCurrency }
            let quote = currencies.first { $0 is CryptoCurrency }

            guard let base = base as? MoonpayCodeMapping, let quote = quote as? MoonpayCodeMapping
            else { throw Exception.invalidInput }

            let baseAmount = input.currency is FiatCurrency ? input.amount : nil
            let quoteAmount = input.currency is CryptoCurrency ? input.amount : nil

            do {
                let buyQuote = try await provider
                    .getBuyQuote(
                        baseCurrencyCode: base.moonpayCode,
                        quoteCurrencyCode: quote.moonpayCode,
                        baseCurrencyAmount: baseAmount,
                        quoteCurrencyAmount: quoteAmount
                    )

                return ExchangeOutput(
                    amount: currency is CryptoCurrency ? buyQuote.quoteCurrencyAmount : buyQuote.totalAmount,
                    currency: currency,
                    processingFee: buyQuote.feeAmount,
                    networkFee: buyQuote.networkFeeAmount,
                    purchaseCost: buyQuote.baseCurrencyAmount,
                    total: buyQuote.totalAmount
                )
            } catch {
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
        ) async throws -> ExchangeRate {
            let exchangeRate = try await provider
                .getPrice(for: cryptoCurrency.moonpayCode, as: fiatCurrency.moonpayCode.uppercased())

            return .init(amount: exchangeRate, cryptoCurrency: cryptoCurrency, fiatCurrency: fiatCurrency)
        }

        private func _getMinAmount(currencies: Moonpay.Currencies, for currency: Currency) -> Double {
            guard let currency = currency as? MoonpayCodeMapping else { return 0.0 }
            return currencies.first { e in e.code == currency.moonpayCode }?.minBuyAmount ?? 0.0
        }

        func getMinAmount(currency: Currency) async throws -> Double {
            let currencies = try await provider
                .getAllSupportedCurrencies()
            return _getMinAmount(currencies: currencies, for: currency)
        }

        func getMinAmounts(_ currency1: Currency, _ currency2: Currency) async throws -> (Double, Double) {
            let currencies = try await provider.getAllSupportedCurrencies()
            return (
                _getMinAmount(currencies: currencies, for: currency1),
                _getMinAmount(currencies: currencies, for: currency2)
            )
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
