import Foundation

protocol BuyExchangeService {
    func convert(input: Buy.ExchangeInput, to currency: Buy.Currency, paymentType: PaymentType) async throws -> Buy
        .ExchangeOutput
    func getExchangeRate(from fiatCurrency: Buy.FiatCurrency, to cryptoCurrency: Buy.CryptoCurrency) async throws -> Buy
        .ExchangeRate
    func isBankTransferEnabled() async throws -> (gbp: Bool, eur: Bool)
}
