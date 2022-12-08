import Foundation
import Resolver

public protocol SellDataServiceProvider {
    associatedtype Transaction
    associatedtype SellQuote
}

class MoonpaySellDataServiceProvider: SellDataServiceProvider {
    private let moonpayAPI = Moonpay.Provider(api: Resolver.resolve())

    func isAvailable() async throws -> Bool {
        let ipAddressesResponse = try await moonpayAPI.ipAddresses()
        return ipAddressesResponse.isSellAllowed
    }
}

extension MoonpaySellDataServiceProvider {
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
