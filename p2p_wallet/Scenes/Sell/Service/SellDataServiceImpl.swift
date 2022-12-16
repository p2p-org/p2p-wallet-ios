import Combine
import Foundation
import Resolver
import SwiftyUserDefaults

class SellDataServiceImpl: SellDataService {
    typealias Provider = MoonpaySellDataServiceProvider
    private var provider = Provider()

    init() {
        statusSubject.send(.initialized)
    }
    
    @Injected private var priceService: PricesService

    @SwiftyUserDefault(keyPath: \.isSellAvailable, options: .cached)
    private var cachedIsAvailable: Bool?

    private let statusSubject = PassthroughSubject<SellDataServiceStatus, Never>()
    lazy var status: AnyPublisher<SellDataServiceStatus, Never> = {
        statusSubject.eraseToAnyPublisher()
    }()

    private let lastUpdateDateSubject = PassthroughSubject<Date, Never>()
    lazy var lastUpdateDate: AnyPublisher<Date, Never> = { lastUpdateDateSubject.eraseToAnyPublisher() }()

    /// List of supported crypto currencies
    private(set) var currency: ProviderCurrency!
    private(set) var fiat: Fiat!
    
    private(set) var incompleteTransactions = CurrentValueSubject<[SellDataServiceTransaction], Never>.init([])
    var incompleteTransactionsPublishers: AnyPublisher<[SellDataServiceTransaction], Never> {
        incompleteTransactions.eraseToAnyPublisher()
    }
    
    /// id - user identifier
    func update(id: String) async throws {
        statusSubject.send(.updating)
        guard
            let currency = try await provider.currencies().filter({ $0.code.uppercased() == "SOL" }).first else {
            statusSubject.send(.error)
            return
        }
        self.currency = currency
        do {
            fiat = try await provider.fiat()
        } catch {
            fiat = .usd
//            fatalError("Unsupported fiat")
        }
        let incompleteTransactions = try await getIncompleteTransactions(transactionId: id)
        self.incompleteTransactions.send(incompleteTransactions)
        statusSubject.send(.ready)
    }
    
    func getCurrentIncompleteTransactions() -> [SellDataServiceTransaction] {
        incompleteTransactions.value
    }

    private func getIncompleteTransactions(transactionId: String) async throws -> [SellDataServiceTransaction] {
        let txs = try await provider.sellTransactions(externalTransactionId: transactionId)
            .filter { $0.status == .waitingForDeposit }

        return try await txs.asyncMap { transaction in
            let detailed = try await provider.detailSellTransaction(id: transaction.id)
            let quoteCurrencyAmount = detailed.quoteCurrencyAmount ?? (self.priceService.currentPrice(for: "SOL")?.value ?? 0) * detailed.baseCurrencyAmount
            guard
//                let quoteCurrencyAmount = detailed.quoteCurrencyAmount,
                let usdRate = detailed.usdRate,
                let eurRate = detailed.eurRate,
                let gbpRate = detailed.gbpRate,
                let depositWallet = detailed.depositWallet?.walletAddress,
                let status = SellDataServiceTransaction.Status(rawValue: detailed.status.rawValue)
            else { return nil }
            return SellDataServiceTransaction(
                id: detailed.id,
                status: status,
                baseCurrencyAmount: detailed.baseCurrencyAmount,
                quoteCurrencyAmount: quoteCurrencyAmount,
                usdRate: usdRate,
                eurRate: eurRate,
                gbpRate: gbpRate,
                depositWallet: depositWallet
            )
        }.compactMap { $0 }
    }

    func transaction(id: String) async throws -> Provider.Transaction {
        try await provider.detailSellTransaction(id: id)
    }

    func deleteTransaction(id: String) async throws {
        try await provider.deleteSellTransaction(id: id)
        var incompleteTransactions = incompleteTransactions.value
        incompleteTransactions.removeAll { $0.id == id }
        self.incompleteTransactions.send(incompleteTransactions)
    }

    func isAvailable() async -> Bool {
        return true
        guard cachedIsAvailable == nil else {
            defer {
                Task {
                    do {
                        cachedIsAvailable = try await provider.isAvailable()
                    } catch {}
                }
            }
            return cachedIsAvailable ?? false
        }
        do {
            cachedIsAvailable = try await provider.isAvailable()
        } catch {
            return false
        }
        return (cachedIsAvailable ?? false)
    }
}

class SellActionServiceMock: SellActionService {
    typealias Provider = MoonpaySellActionServiceProvider
    private var provider = Provider()

    @Injected private var userWalletManager: UserWalletManager

    func sellQuote(
        baseCurrencyCode: String,
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        extraFeePercentage: Double
    ) async throws -> Provider.Quote {
        try await provider.sellQuote(
            baseCurrencyCode: baseCurrencyCode,
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount
        )
    }

    func createSellURL(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalTransactionId: String
    ) throws -> URL {
        #if !RELEASE
        let endpoint = String.secretConfig("MOONPAY_STAGING_SELL_ENDPOINT")!
        let apiKey = String.secretConfig("MOONPAY_STAGING_API_KEY")!
        #else
        let endpoint = String.secretConfig("MOONPAY_PRODUCTION_SELL_ENDPOINT")!
        let apiKey = String.secretConfig("MOONPAY_PRODUCTION_API_KEY")!
        #endif

        var components = URLComponents(string: endpoint + "sell")!
        components.queryItems = [
            .init(name: "apiKey", value: apiKey),
            .init(name: "baseCurrencyCode", value: "sol"),
            .init(name: "refundWalletAddress", value: userWalletManager.wallet?.account.publicKey.base58EncodedString),
            .init(name: "quoteCurrencyCode", value: quoteCurrencyCode),
            .init(name: "baseCurrencyAmount", value: baseCurrencyAmount.toString()),
            .init(name: "externalTransactionId", value: externalTransactionId),
            .init(name: "externalCustomerId", value: externalTransactionId)
        ]

        guard let url = components.url else {
            throw SellActionServiceError.invalidURL
        }
        return url
    }

    func saveTransaction() async throws {}
    func deleteTransaction() async throws {}
}
