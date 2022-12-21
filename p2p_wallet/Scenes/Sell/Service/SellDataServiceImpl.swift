import Combine
import Foundation
import Resolver
import SwiftyUserDefaults

enum SellDataServiceError: Error {
    case userIdNotFound
    case couldNotLoadSellData
}

final class SellDataServiceImpl: SellDataService {
    
    // MARK: - Associated type

    typealias Provider = MoonpaySellDataServiceProvider
    
    // MARK: - Dependencies

    @Injected private var priceService: PricesService
    @Injected private var userWalletManager: UserWalletManager
    @Injected private var sellTransactionsRepository: SellTransactionsRepository
    
    // MARK: - Properties

    private var provider = Provider()
    
    @SwiftyUserDefault(keyPath: \.isSellAvailable, options: .cached)
    private var cachedIsAvailable: Bool?
    
    @Published private var status: SellDataServiceStatus = .initialized
    var statusPublisher: AnyPublisher<SellDataServiceStatus, Never> {
        $status.eraseToAnyPublisher()
    }
    
    @Published private(set) var transactions: [SellDataServiceTransaction] = []
    var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> {
        $transactions.eraseToAnyPublisher()
    }
    
    var currency: MoonpaySellDataServiceProvider.MoonpayCurrency?
    
    var fiat: Fiat?
    
    var userId: String? { userWalletManager.wallet?.moonpayExternalClientId }
    
    // MARK: - Methods
    
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
    
    func update() async {
        // mark as updating
        status = .updating
        
        // get currency
        do {
            let (currency, fiat, _) = try await(
                provider.currencies().filter({ $0.code.uppercased() == "SOL" }).first,
                provider.fiat(),
                updateIncompletedTransactions()
            )
            if currency == nil {
                throw SellDataServiceError.couldNotLoadSellData
            }
            self.currency = currency
            self.fiat = fiat
            status = .ready
        } catch {
            self.currency = nil
            self.fiat = nil
            status = .error(SellDataServiceError.couldNotLoadSellData)
            return
        }
    }
    
    func updateIncompletedTransactions() async throws {
        // get user id
        guard let userId else {
            status = .error(SellDataServiceError.userIdNotFound)
            return
        }
        
        let txs = try await provider.sellTransactions(externalTransactionId: userId)

        let incompletedTransactions: [SellDataServiceTransaction] = try await txs.asyncMap { transaction in
            let detailed = try await provider.detailSellTransaction(id: transaction.id)
            let quoteCurrencyAmount = detailed.quoteCurrencyAmount ?? (self.priceService.currentPrice(for: "SOL")?.value ?? 0) * detailed.baseCurrencyAmount
            guard
                let usdRate = detailed.usdRate,
                let eurRate = detailed.eurRate,
                let gbpRate = detailed.gbpRate,
                let depositWallet = detailed.depositWallet?.walletAddress,
                let status = SellDataServiceTransaction.Status(rawValue: detailed.status.rawValue)
            else { return nil }
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
            let createdAt = dateFormatter.date(from: detailed.createdAt)
            
            return SellDataServiceTransaction(
                id: detailed.id,
                createdAt: createdAt,
                status: status,
                baseCurrencyAmount: detailed.baseCurrencyAmount,
                quoteCurrencyAmount: quoteCurrencyAmount,
                usdRate: usdRate,
                eurRate: eurRate,
                gbpRate: gbpRate,
                depositWallet: depositWallet
            )
        }.compactMap { $0 }
        
        await sellTransactionsRepository.setTransactions(incompletedTransactions)
        transactions = await sellTransactionsRepository.transactions
    }
    
    func getTransactionDetail(id: String) async throws -> Provider.Transaction {
        try await provider.detailSellTransaction(id: id)
    }

    func deleteTransaction(id: String) async throws {
        try await provider.deleteSellTransaction(id: id)
        await sellTransactionsRepository.deleteTransaction(id: id)
        transactions = await sellTransactionsRepository.transactions
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
        let endpoint: String
        let apiKey: String
        switch Defaults.moonpayEnvironment {
        case .production:
            endpoint = .secretConfig("MOONPAY_PRODUCTION_SELL_ENDPOINT")!
            apiKey = .secretConfig("MOONPAY_PRODUCTION_API_KEY")!
        case .sandbox:
            endpoint = .secretConfig("MOONPAY_STAGING_SELL_ENDPOINT")!
            apiKey = .secretConfig("MOONPAY_STAGING_API_KEY")!
        }

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
