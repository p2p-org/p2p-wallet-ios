import Combine
import Foundation
import Resolver
import SolanaPricesAPIs
import SolanaSwift

typealias TokenPriceMap = [String: CurrentPrice]

protocol PricesServiceType {
    // Publishers
    var currentPricesPublisher: AnyPublisher<TokenPriceMap, Never> { get }
    var isPricesAvailablePublisher: AnyPublisher<Bool, Never> { get }
    var isPricesAvailable: Bool { get }

    // Getters
    func getWatchList() -> [Token]
    func currentPrice(mint: String) -> CurrentPrice?

    // Actions
    func clearCurrentPrices()
    func addToWatchList(_ tokens: [Token])
    func fetchPrices(tokens: [Token], toFiat: Fiat)
    func fetchAllTokensPriceInWatchList()
    func getCurrentPrices(tokens: [Token]?, toFiat: Fiat) async throws -> TokenPriceMap
    func startObserving()
    func stopObserving()
}

class PricesService {
    // MARK: - Nested type

    enum Error: Swift.Error {
        case notFound
        case unknown
    }

    // MARK: - Constants

    private let refreshInterval: TimeInterval = 15 * 60 // 15 minutes

    // MARK: - Dependencies

    @Injected private var storage: PricesStorage
    @Injected private var api: SolanaPricesAPI
    @Injected private var notificationService: NotificationService

    // MARK: - Properties

    private var watchList = [
        Token(.renBTC), Token(.nativeSolana), Token(.usdc), Token(.eth), Token(.usdt),
    ]
    private var timer: Timer?
    private lazy var currentPricesSubject = CurrentValueSubject<TokenPriceMap, Never>([:])
    private lazy var isPricesAvailableSubject = CurrentValueSubject<Bool, Never>(true)

    var fetchingTask: Task<Void, Swift.Error>?

    // MARK: - Initializer

    init() {
        // get current price
        Task {
            // migration
            await migrate()

            var initialValue = await storage.retrievePrices()
            if initialValue.values.isEmpty {
                initialValue = try await getCurrentPrices()
            }
            currentPricesSubject.send(initialValue)

            // reload
            try await reload()
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Helpers

    private func migrate() async {
        // First migration to fix COPE token
        let migration1Key = "PricesService.migration1Key"

        if UserDefaults.standard.bool(forKey: migration1Key) == false {
            // clear current cache
            await storage.savePrices([:])

            // mark as migrated
            UserDefaults.standard.set(true, forKey: migration1Key)
        }
    }

    private func reload() async throws {
        guard !watchList.isEmpty else { return }
        let currentPrice = try await getCurrentPrices(tokens: watchList, toFiat: Defaults.fiat)
        currentPricesSubject.send(currentPrice)
    }

    func getCurrentPrices(tokens: [Token]? = nil, toFiat: Fiat = Defaults.fiat) async throws -> TokenPriceMap {
        let coins: [Token] = (tokens ?? watchList)
            .filter { !$0.symbol.contains("-") && !$0.symbol.contains("/") }
            .unique
        guard !coins.isEmpty else {
            return currentPricesSubject.value
        }

        let newPrices = try await api.getCurrentPrices(coins: coins, toFiat: toFiat.code)
        var prices = currentPricesSubject.value
        for newPrice in newPrices where newPrice.value != nil {
            prices[newPrice.key.address] = newPrice.value
        }
        await storage.savePrices(prices)
        return prices
    }
}

extension PricesService: PricesServiceType {
    var currentPricesPublisher: AnyPublisher<TokenPriceMap, Never> {
        currentPricesSubject.eraseToAnyPublisher()
    }
    
    var isPricesAvailablePublisher: AnyPublisher<Bool, Never> {
        isPricesAvailableSubject.eraseToAnyPublisher()
    }
    
    var isPricesAvailable: Bool {
        isPricesAvailableSubject.value
    }

    func getWatchList() -> [Token] {
        watchList
    }

    func currentPrice(mint: String) -> CurrentPrice? {
        currentPricesSubject.value[mint]
    }

    func clearCurrentPrices() {
        currentPricesSubject.send([:])

        Task {
            await storage.savePrices([:])
        }
    }

    func addToWatchList(_ tokens: [Token]) {
        for token in tokens {
            watchList.appendIfNotExist(token)
        }
    }

    func fetchPrices(tokens: [Token], toFiat: Fiat = Defaults.fiat) {
        guard !tokens.isEmpty else { return }

        fetchingTask?.cancel()
        fetchingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let currentPrice = try await self.getCurrentPrices(tokens: tokens, toFiat: toFiat)
                try Task.checkCancellation()
                self.currentPricesSubject.send(currentPrice)
                self.isPricesAvailableSubject.send(true)
            } catch {
                guard Task.isNotCancelled else { return }
                self.notificationService
                    .showInAppNotification(
                        .custom(
                            "😢",
                            L10n.TokenRatesAreUnavailable.everythingWorksAsUsualAndAllFundsAreSafe
                        )
                    )
                self.isPricesAvailableSubject.send(false)

                throw error
            }
        }
    }

    func fetchAllTokensPriceInWatchList() {
        guard !watchList.isEmpty else { return }
        fetchPrices(tokens: watchList)
    }

    func fetchHistoricalPrice(for coinName: String, period: Period) async throws -> [PriceRecord] {
        do {
            let prices = try await api.getHistoricalPrice(
                of: coinName,
                fiat: Defaults.fiat.code,
                period: period
            )
            if prices.isEmpty { throw Error.notFound }
            return prices
        } catch {
            if Defaults.fiat.code.uppercased() != "USD" {
                // retry with different fiat
                async let pricesInUSD = api.getHistoricalPrice(of: coinName, fiat: "USD", period: period)
                async let valueInUSD = api.getValueInUSD(fiat: Defaults.fiat.code)

                guard let rate = try await valueInUSD else { return [] }
                var records = try await pricesInUSD
                for i in 0 ..< records.count {
                    records[i] = records[i].converting(exchangeRate: rate)
                }
                return records
            }
            throw error
        }
    }

    func startObserving() {
        fetchAllTokensPriceInWatchList()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: { [weak self] _ in
            self?.fetchAllTokensPriceInWatchList()
        })
    }

    func stopObserving() {
        timer?.invalidate()
    }
}

private extension Array where Element: Equatable {
    var unique: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            guard !uniqueValues.contains(item) else { return }
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}

extension Token {
    init(_ token: Token, customSymbol: String? = nil) {
        self = Token(
            _tags: nil,
            chainId: token.chainId,
            address: token.address,
            symbol: customSymbol ?? token.symbol,
            name: token.name,
            decimals: token.decimals,
            logoURI: token.logoURI,
            extensions: token.extensions
        )
    }
}
