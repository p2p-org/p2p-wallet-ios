import Foundation
import Moonpay

public enum MoonpaySellDataServiceProviderError: Error {
    case unsupportedRegion(ProviderRegion)
}

public class MoonpaySellDataServiceProvider: SellDataServiceProvider {
    // MARK: - Type aliases

    public typealias Currency = MoonpayCurrency
    public typealias Transaction = MoonpayTransaction
    public typealias Fiat = MoonpayFiat
    public typealias Region = Moonpay.Provider.IpAddressResponse

    // MARK: - Properties

    private let moonpayAPI: Moonpay.Provider

    // MARK: - Initializer

    public init(moonpayAPI: Moonpay.Provider) {
        self.moonpayAPI = moonpayAPI
    }

    // MARK: - Methods

    func isAvailable() async throws -> Bool {
        try await moonpayAPI.ipAddresses().isSellAllowed
    }

    func fiat(region: ProviderRegion?) async throws -> Fiat {
        func fiatByApha3(region: ProviderRegion) throws -> Fiat {
            if moonpayAPI.UKAlpha3Code() == region.alpha3 {
                return .gbp
            } else if moonpayAPI.bankTransferAvailableAlpha3Codes().contains(region.alpha3) {
                return .eur
            } else if moonpayAPI.USAlpha3Code() == region.alpha3 {
                return .usd
            }
            throw MoonpaySellDataServiceProviderError.unsupportedRegion(region)
        }
        if let region {
            return try fiatByApha3(region: region)
        } else {
            let resp = try await moonpayAPI.ipAddresses()
            return try fiatByApha3(region: resp)
        }
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

    public func sellTransactions(externalCustomerId: String) async throws -> [Transaction] {
        try await moonpayAPI.sellTransactions(externalCustomerId: externalCustomerId)
    }

    public func detailSellTransaction(id: String) async throws -> Transaction {
        try await moonpayAPI.sellTransaction(id: id)
    }

    public func deleteSellTransaction(id: String) async throws {
        try await moonpayAPI.deleteSellTransaction(id: id)
    }
}

public extension MoonpaySellDataServiceProvider {
    struct MoonpayCurrency: ProviderCurrency, Codable {
        public var id: String
        public var name: String
        public var code: String
        public var precision: Int
        public var minSellAmount: Double?
        public var maxSellAmount: Double?
        public var isSuspended: Bool
    }

    enum MoonpayFiat: String, ProviderFiat {
        public var code: String {
            rawValue.uppercased()
        }

        case gbp
        case eur
        case usd
    }

    struct MoonpayTransaction: Codable, ProviderTransaction {
        public var id: String
        public var createdAt: String
        public var updatedAt: String
        public var baseCurrencyAmount: Double
        public var quoteCurrencyAmount: Double?
        public var feeAmount: Double?
        public var extraFeeAmount: Double?
        public var status: MoonpayTransaction.Status
        public var failureReason: String?
        public var refundWalletAddress: String?
        public var depositHash: String?
        public var depositWalletId: String
        public var quoteCurrencyId: String
        public var baseCurrencyId: String
        public var depositWallet: DepositWallet?
        public var usdRate: Double?
        public var eurRate: Double?
        public var gbpRate: Double?
    }
}

public extension MoonpaySellDataServiceProvider.MoonpayTransaction {
    enum Status: String, Codable, Hashable {
        case waitingForDeposit
        case pending
        case failed
        case completed
    }

    struct DepositWallet: Codable, Equatable, Hashable {
        public var walletAddress: String
    }
}

extension Moonpay.Provider.IpAddressResponse: ProviderRegion {}
