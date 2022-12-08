import Foundation
import Resolver

public protocol SellDataServiceProvider {
    associatedtype Transaction
    associatedtype SellQuote
}

class MoonpaySellDataServiceProvider: SellDataServiceProvider {
    @Injected private var moonpayAPI: Moonpay.Provider

    func isAvailable() async throws -> Bool {
        let ipAddressesResponse = try await moonpayAPI.ipAddresses()
        return ipAddressesResponse.isSellAllowed
    }

    func sellQuote(
        baseCurrencyCode: String,
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        extraFeePercentage: Double = 0
    ) async throws -> MoonpaySellDataServiceProvider.SellQuote {
        let result = try await moonpayAPI.getSellQuote(
            baseCurrencyCode: baseCurrencyCode,
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount,
            extraFeePercentage: extraFeePercentage)
        return SellQuote(minSellAmount: 0)
    }

    func currencies() async throws -> [Currency] {
        let currencies = try await moonpayAPI.getAllSupportedCurrencies()
        return currencies.map { cur in
            Currency(
                id: cur.id,
                name: cur.name,
                code: cur.code,
                precision: cur.precision ?? 0,
                minSellAmount: cur.minSellAmount ?? 0,
                maxSellAmount: cur.maxSellAmount ?? 0,
                isSuspended: cur.isSuspended ?? false
            )
        }
    }
}

extension MoonpaySellDataServiceProvider {
    struct Currency {
        var id: String
        var name: String
        var code: String
        var precision: Int
        var minSellAmount: Double?
        var maxSellAmount: Double?
        var isSuspended: Bool
    }

    struct SellQuote: Codable {
        var minSellAmount: Double
    }

    struct Transaction: Codable {
        var id: String
        var createdAt: Date
        var updatedAt: Date
        var baseCurrencyAmount: Double
        var quoteCurrencyAmount: Double
        var feeAmount: Double
        var extraFeeAmount: Double
        var status: Transaction.Status
        var failureReason: String?
        var refundWalletAddress: String?
        var depositHash: String?
        var quoteCurrencyId: String
        var baseCurrencyId: String
    }
}

extension MoonpaySellDataServiceProvider.Transaction {
    enum Status: String, Codable {
        case waitingForDeposit
        case pending
        case failed
        case completed
    }
}
