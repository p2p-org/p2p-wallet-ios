import Combine
import Foundation

public final class MoonpaySellDataService: SellDataService {
    
    // MARK: - Associated type

    public typealias Provider = MoonpaySellDataServiceProvider
    
    // MARK: - Dependencies

    private let provider: Provider
    private let priceProvider: SellPriceProvider
    private let sellTransactionsRepository: SellTransactionsRepository
    
    // MARK: - Properties
    
    public private(set) var isAvailable: Bool
    
    @Published private var status: SellDataServiceStatus = .initialized
    public var statusPublisher: AnyPublisher<SellDataServiceStatus, Never> {
        $status.eraseToAnyPublisher()
    }
    
    @Published public private(set) var transactions: [SellDataServiceTransaction] = []
    public var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> {
        $transactions.eraseToAnyPublisher()
    }
    
    public var currency: MoonpaySellDataServiceProvider.MoonpayCurrency?
    
    public var fiat: MoonpaySellDataServiceProvider.Fiat?
    
    public let userId: String
    
    // MARK: - Initializer
    public init(
        userId: String,
        provider: Provider,
        priceProvider: SellPriceProvider,
        sellTransactionsRepository: SellTransactionsRepository
    ) {
        self.userId = userId
        self.provider = provider
        self.priceProvider = priceProvider
        self.sellTransactionsRepository = sellTransactionsRepository
        self.isAvailable = false
    }
    
    // MARK: - Methods
    
    public func checkAvailability() async {
        isAvailable = (try? await provider.isAvailable()) ?? false
    }
    
    public func update() async {
        // mark as updating
        status = .updating
        
        // get currency
        do {
            isAvailable = try await provider.isAvailable()
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
        } catch let error {
            debugPrint(error)
            self.currency = nil
            self.fiat = nil
            status = .error(SellDataServiceError.couldNotLoadSellData)
            return
        }
    }
    
    public func updateIncompletedTransactions() async throws {
        let txs = try await provider.sellTransactions(externalCustomerId: userId)
        
        // TODO: - Watch for network call limits
        let incompletedTransactions = try await withThrowingTaskGroup(of: SellDataServiceTransaction?.self) { group in
            var transactions = [SellDataServiceTransaction?]()
            
            for id in txs.map(\.id) {
                group.addTask { [unowned self] in
                    do {
                        let detailed = try await self.provider.detailSellTransaction(id: id)
                    
                        let quoteCurrencyAmount = detailed.quoteCurrencyAmount ?? (priceProvider.getCurrentPrice(for: "SOL") ?? 0) * detailed.baseCurrencyAmount
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
                            depositWallet: depositWallet,
                            fauilureReason: detailed.failureReason
                        )
                    } catch {
                        return nil
                    }
                }
            }
            
            // grab results
            for try await tx in group {
                transactions.append(tx)
            }
            
            return transactions
        }.compactMap {$0}
        
        await sellTransactionsRepository.setTransactions(incompletedTransactions)
        transactions = await sellTransactionsRepository.transactions
    }
    
    public func getTransactionDetail(id: String) async throws -> Provider.Transaction {
        try await provider.detailSellTransaction(id: id)
    }

    public func deleteTransaction(id: String) async throws {
        try await provider.deleteSellTransaction(id: id)
        await sellTransactionsRepository.deleteTransaction(id: id)
        transactions = await sellTransactionsRepository.transactions
    }
    
    public func markAsPending(id: String) async {
        await sellTransactionsRepository.markAsPending(id: id)
        transactions = await sellTransactionsRepository.transactions
    }
}
