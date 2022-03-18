//
// Created by Giang Long Tran on 21.02.2022.
//

import Foundation
import RxSwift

extension Buy {
    struct MoonpayExchange: Buy.ExchangeService {
        let provider: Moonpay.Provider
        
        init(provider: Moonpay.Provider) { self.provider = provider }
        
        func convert(input: ExchangeInput, to currency: Currency) -> Single<ExchangeOutput> {
            let currencies = [input.currency, currency]
            let base = currencies.first { $0 is FiatCurrency }
            let quote = currencies.first { $0 is CryptoCurrency }
            
            guard let base = base, let quote = quote
                else { return .error(Exception.invalidInput) }
            
            let baseAmount = input.currency is FiatCurrency ? input.amount : nil
            let quoteAmount = input.currency is CryptoCurrency ? input.amount : nil
            
            return provider
                .getBuyQuote(
                    baseCurrencyCode: base.toString(),
                    quoteCurrencyCode: quote.toString(),
                    baseCurrencyAmount: baseAmount,
                    quoteCurrencyAmount: quoteAmount)
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
                        case .message(message: let message):
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
            provider
                .getPrice(for: cryptoCurrency.rawValue, as: fiatCurrency.rawValue.uppercased())
                .map { exchangeRate in .init(amount: exchangeRate, cryptoCurrency: cryptoCurrency, fiatCurrency: fiatCurrency) }
        }
        
        private func _getMinAmount(currencies: Moonpay.Currencies, for currency: Currency) -> Double {
            currencies.first { e in e.code == currency.toString() }?.minBuyAmount ?? 0.0
        }
        
        func getMinAmounts(_ currency1: Currency, _ currency2: Currency) -> Single<(Double, Double)> {
            provider.getAllSupportedCurrencies()
                .map { currencies in
                    (
                        _getMinAmount(currencies: currencies, for: currency1),
                        _getMinAmount(currencies: currencies, for: currency2)
                    )
                }
        }
        
        func getMinAmount(currency: Currency) -> Single<Double> {
            provider
                .getAllSupportedCurrencies()
                .map { _getMinAmount(currencies: $0, for: currency) }
        }
    }
}
