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
                        amount: quote.quoteCurrencyAmount,
                        currency: currency,
                        processingFee: quote.extraFeeAmount,
                        networkFee: quote.networkFeeAmount,
                        total: quote.totalAmount
                    )
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
    }
    
}