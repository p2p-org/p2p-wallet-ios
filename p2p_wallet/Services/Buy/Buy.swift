//
// Created by Giang Long Tran on 14.02.2022.
//

import Foundation

struct Buy {
    public typealias ProcessingService = BuyProcessingServiceType
    public typealias ExchangeService = BuyExchangeServiceType
    public typealias Currency = BuyCurrencyType
    
    enum FiatCurrency: String, BuyCurrencyType {
        case usd = "usd"
        
        func toString() -> String { rawValue }
    }
    
    enum CryptoCurrency: String, BuyCurrencyType {
        case eth = "eth"
        case sol = "sol"
        case usdt = "usdt"
        
        func toString() -> String { rawValue }
        
        static let all: Set<CryptoCurrency> = [.eth, .sol, .usdt]
    }
    
    struct ExchangeInput {
        let amount: Double
        let currency: Currency
        
        func swap(with output: ExchangeOutput) -> (ExchangeInput, ExchangeOutput) {
            (
                .init(amount: output.amount, currency: output.currency),
                .init(amount: amount, currency: currency, processingFee: output.processingFee, networkFee: output.networkFee, total: output.total)
            )
        }
    }
    
    struct ExchangeOutput {
        let amount: Double
        let currency: Currency
        
        let processingFee: Double
        let networkFee: Double
        let total: Double
    }
    
    struct ExchangeRate {
        let amount: Double
        let cryptoCurrency: CryptoCurrency
        let fiatCurrency: FiatCurrency
    }
    
    enum Exception: Error {
        case invalidInput
    }
}
