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
        case usdc = "usdc"
        
        func toString() -> String { rawValue }
    
        var fullname: String {
            switch self {
            case .eth:
                return "Ethereum"
            case .sol:
               return "Solana"
            case .usdc:
                return "Usd coin"
            }
        }
        
        var code: String {
            switch self {
            case .eth:
                return "eth"
            case .sol:
                return "sol"
            case .usdc:
                return "usdc_sol"
            }
        }
        
        static let all: Set<CryptoCurrency> = [.eth, .sol, .usdc]
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
        case message(String)
    }
}
