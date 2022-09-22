//
// Created by Giang Long Tran on 21.02.2022.
//

import Foundation

protocol BuyExchangeServiceType {
    func getMinAmount(currency: Buy.Currency) async throws -> Double
    func getMinAmounts(_ currency1: Buy.Currency, _ currency2: Buy.Currency) async throws -> (Double, Double)

    func convert(input: Buy.ExchangeInput, to currency: Buy.Currency) async throws -> Buy.ExchangeOutput
    func getExchangeRate(from fiatCurrency: Buy.FiatCurrency, to cryptoCurrency: Buy.CryptoCurrency)
    async throws -> Buy.ExchangeRate
}

/// New Exchange Service without Rx
protocol BuyExchangeService {
    func getMinAmount(currency: Buy.Currency) async throws -> Double
    func getMinAmounts(_ currency1: Buy.Currency, _ currency2: Buy.Currency) async throws -> (Double, Double)
    func convert(input: Buy.ExchangeInput, to currency: Buy.Currency, paymentType: PaymentType) async throws -> Buy
        .ExchangeOutput
    func getExchangeRate(from fiatCurrency: Buy.FiatCurrency, to cryptoCurrency: Buy.CryptoCurrency) async throws -> Buy
        .ExchangeRate
    func isBankTransferEnabled() async throws -> (gbp: Bool, eur: Bool)
}
