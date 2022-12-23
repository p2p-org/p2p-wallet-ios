import Foundation
import Resolver

enum MoonpaySellDataServiceProviderError: Error {
    case unsupportedRegion
}

class MoonpaySellDataServiceProvider: SellDataServiceProvider {
    typealias Currency = MoonpaySellDataServiceProvider.MoonpayCurrency
    typealias Transaction = MoonpaySellDataServiceProvider.MoonpayTransaction

    @Injected private var moonpayAPI: Moonpay.Provider

    private(set) var ipAddressesResponse: Moonpay.Provider.IpAddressResponse?
    func isAvailable() async throws -> Bool {
        guard let ipAddressesResponse else {
            let resp = try await moonpayAPI.ipAddresses()
            ipAddressesResponse = resp
            return resp.isSellAllowed
        }
        return ipAddressesResponse.isSellAllowed
    }

    func fiat() async throws -> Fiat {
        func fiatByApha3(alpha3: String) throws -> Fiat {
            if moonpayAPI.UKAlpha3Code() == alpha3 {
                return .gbp
            } else if moonpayAPI.bankTransferAvailableAlpha3Codes().contains(alpha3) {
                return .eur
            } else if moonpayAPI.USAlpha3Code() == alpha3 {
                return .usd
            }
            throw MoonpaySellDataServiceProviderError.unsupportedRegion
        }
        guard let ipAddressesResponse else {
            let resp = try await moonpayAPI.ipAddresses()
            ipAddressesResponse = resp
            return try fiatByApha3(alpha3: resp.alpha3)
        }
        return try fiatByApha3(alpha3: ipAddressesResponse.alpha3)
    }

    func currencies() async throws -> [Currency] {
        let currencies = try await moonpayAPI.getAllSupportedCurrencies()
        return currencies.map { cur in
            MoonpayCurrency(
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

    func sellTransactions(externalTransactionId: String) async throws -> [Transaction] {
        try await moonpayAPI.sellTransactions(externalTransactionId: externalTransactionId)
    }

    func detailSellTransaction(id: String) async throws -> Transaction {
        try await moonpayAPI.sellTransaction(id: id)
    }

    func deleteSellTransaction(id: String) async throws {
        try await moonpayAPI.deleteSellTransaction(id: id)
    }
}

extension MoonpaySellDataServiceProvider {
    struct MoonpayCurrency: ProviderCurrency, Codable {
        var id: String
        var name: String
        var code: String
        var precision: Int
        var minSellAmount: Double?
        var maxSellAmount: Double?
        var isSuspended: Bool
    }

    struct MoonpayTransaction: Codable, ProviderTransaction {
        var id: String
        var createdAt: String
        var updatedAt: String
        var baseCurrencyAmount: Double
        var quoteCurrencyAmount: Double?
        var feeAmount: Double?
        var extraFeeAmount: Double?
        var status: MoonpayTransaction.Status
        var failureReason: String?
        var refundWalletAddress: String?
        var depositHash: String?
        var depositWalletId: String
        var quoteCurrencyId: String
        var baseCurrencyId: String
        var depositWallet: DepositWallet?
        var usdRate: Double?
        var eurRate: Double?
        var gbpRate: Double?
    }
}

extension MoonpaySellDataServiceProvider.MoonpayTransaction {
    enum Status: String, Codable, Hashable {
        case waitingForDeposit
        case pending
        case failed
        case completed
    }

    struct DepositWallet: Codable, Equatable, Hashable {
        var walletAddress: String
    }
}
