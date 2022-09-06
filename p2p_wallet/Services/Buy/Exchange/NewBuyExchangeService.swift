import Foundation
import SolanaSwift

struct MoonpayExchange: BuyExchangeService {
    let provider: Moonpay.Provider

    init(provider: Moonpay.Provider) { self.provider = provider }

    func convert(
        input: Buy.ExchangeInput,
        to currency: Buy.Currency,
        paymentType: PaymentType
    ) async throws -> Buy.ExchangeOutput {
        let currencies = [input.currency, currency]
        let base = currencies.first { $0 is Buy.FiatCurrency }
        let quote = currencies.first { $0 is Buy.CryptoCurrency }

        guard
            let base = base as? MoonpayCodeMapping,
            let quote = quote as? MoonpayCodeMapping
        else {
//            throw Exception.invalidInput
            fatalError()
        }

        let baseAmount = input.currency is Buy.Currency ? input.amount : nil
        let quoteAmount = input.currency is Buy.CryptoCurrency ? input.amount : nil

        do {
            let buyQuote = try await provider
                .getBuyQuote(
                    baseCurrencyCode: base.moonpayCode,
                    quoteCurrencyCode: quote.moonpayCode,
                    baseCurrencyAmount: baseAmount,
                    quoteCurrencyAmount: quoteAmount,
                    paymentMethod: PaymentType.card == paymentType ? .creditDebitCard : .sepaBankTransfer
                )

            return Buy.ExchangeOutput(
                amount: currency is Buy.CryptoCurrency ? buyQuote.quoteCurrencyAmount : buyQuote.totalAmount,
                currency: currency,
                processingFee: buyQuote.feeAmount,
                networkFee: buyQuote.networkFeeAmount,
                purchaseCost: buyQuote.baseCurrencyAmount,
                total: buyQuote.totalAmount
            )
        } catch {
            throw error
        }
    }

    func getExchangeRate(
        from fiatCurrency: Buy.FiatCurrency,
        to cryptoCurrency: Buy.CryptoCurrency
    ) async throws -> Buy.ExchangeRate {
        let exchangeRate = try await provider
            .getPrice(for: cryptoCurrency.moonpayCode, as: fiatCurrency.moonpayCode.uppercased())

        return .init(amount: exchangeRate, cryptoCurrency: cryptoCurrency, fiatCurrency: fiatCurrency)
    }

    private func _getMinAmount(currencies: Moonpay.Currencies, for currency: BuyCurrencyType) -> Double {
        guard let currency = currency as? MoonpayCodeMapping else { return 0.0 }
        return currencies.first { e in e.code == currency.moonpayCode }?.minBuyAmount ?? 0.0
    }

    func getMinAmount(currency: Buy.Currency) async throws -> Double {
        let currencies = try await provider
            .getAllSupportedCurrencies()
        return _getMinAmount(currencies: currencies, for: currency)
    }

    func getMinAmounts(_ currency1: Buy.Currency, _ currency2: Buy.Currency) async throws -> (Double, Double) {
        let currencies = try await provider.getAllSupportedCurrencies()
        return (
            _getMinAmount(currencies: currencies, for: currency1),
            _getMinAmount(currencies: currencies, for: currency2)
        )
    }

    /// Weather banks are available for this provider
    func isBankTransferEnabled() async throws -> (gbp: Bool, eur: Bool) {
        let banks = try await provider.bankTransferAvailability()
        return (gbp: banks.gbp, eur: banks.eur)
    }
}

extension Fiat {
    func fiatCurrency(_ fiat: Fiat) -> Buy.FiatCurrency? {
        Buy.FiatCurrency(rawValue: fiat.rawValue)
    }

    func buyFiatCurrency() -> Buy.FiatCurrency? {
        Buy.FiatCurrency(rawValue: rawValue)
    }
}

extension Token {
    func buyCryptoCurrency() -> Buy.CryptoCurrency? {
        Buy.CryptoCurrency(rawValue: symbol.lowercased())
    }
}
