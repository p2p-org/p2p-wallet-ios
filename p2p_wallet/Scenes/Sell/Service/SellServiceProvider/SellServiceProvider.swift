import Foundation
import Resolver

public protocol SellDataServiceProvider {
    associatedtype Transaction
}

class MoonpaySellDataServiceProvider: SellDataServiceProvider {
    private let moonpayAPI = Moonpay.Provider(api: Resolver.resolve())

    func isAvailable() async throws -> Bool {
        let ipAddressesResponse = try await moonpayAPI.ipAddresses()
        return ipAddressesResponse.isSellAllowed
    }

}

extension MoonpaySellDataServiceProvider {
    struct Transaction: Codable {
        var id: String
        var createdAt: Date
        var updatedAt
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

    extension Transaction {
        enum Status: String, Codable {
            case waitingForDeposit
            case pending
            case failed
            case completed
        }
    }
}
