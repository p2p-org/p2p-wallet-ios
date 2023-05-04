import Combine
import Resolver
import AnalyticsManager
import SolanaSwift
import SolanaPricesAPIs

final class DerivableAccountsViewModel: BaseViewModel, ObservableObject {

    private enum FetcherState {
        case initializing
        case loading
        case loaded
        case error
    }

    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var notificationsService: NotificationService
    @Injected private var appEventHandler: AppEventHandlerType
    @Injected private var iCloudStorage: ICloudStorageType
    @Injected private var pricesFetcher: SolanaPricesAPI
    @Injected private var solanaAPIClient: SolanaAPIClient

    // MARK: - Subjects

    let selectDerivableType = PassthroughSubject<DerivablePath, Never>()
    let didSucceed = PassthroughSubject<([String], DerivablePath), Never>()
    let back = PassthroughSubject<Void, Never>()

    var derivableType: DerivablePath.DerivableType?
    @Published var selectedDerivablePath = DerivablePath.default
    @Published var loading = false
    @Published var data: [DerivableAccount]

    // MARK: - Properties

    private let phrases: [String]
    private var derivablePath: DerivablePath?
    private let cache = DerivableAccountsCache()
    private var task: Task<Void, Error>?
    private var state = FetcherState.initializing
    private var error: Error?

    // MARK: - Initializer

    init(phrases: [String]) {
        self.phrases = phrases
        self.data = []
        super.init()

        select(derivableType: selectedDerivablePath.type)
        reload()
        logOpen()
    }

    // MARK: - Actions

    func selectDerivablePath(_ path: DerivablePath) {
        selectedDerivablePath = path
        restoreAccount()
    }

    func select(derivableType: DerivablePath.DerivableType) {
        selectedDerivablePath = DerivablePath(
            type: derivableType,
            walletIndex: selectedDerivablePath.walletIndex,
            accountIndex: selectedDerivablePath.accountIndex
        )
        cancelRequest()
        self.derivableType = derivableType
        reload()
    }

    // MARK: - Private methods

    private func restoreAccount() {
        // Cancel any requests
        cancelRequest()

        loading = true
        // Send to handler
        Task {
            do {
                try await self.proceedSelection(derivablePath: selectedDerivablePath, phrases: phrases)
            } catch {
                self.notificationsService.showToast(title: nil, text: error.readableDescription)
            }
            self.loading = false
        }
    }

    private func proceedSelection(derivablePath: DerivablePath, phrases: [String]) async throws {
        logRestoreClick()
        didSucceed.send((phrases, derivablePath))
    }

    private func createRequest() async throws -> [DerivableAccount] {
        let accounts = try await createDerivableAccounts()
        Task {
            try? await(
                self.fetchSOLPrice(),
                self.fetchBalances(accounts: accounts.map(\.info.publicKey.base58EncodedString))
            )
        }
        return accounts
    }

    private func createDerivableAccounts() async throws -> [DerivableAccount] {
        let phrases = self.phrases
        guard let derivableType else {
            throw SolanaError.unknown
        }
        return try await withThrowingTaskGroup(of: (Int, KeyPair).self) { group in
            var accounts = [(Int, DerivableAccount)]()

            for i in 0 ..< 5 {
                group.addTask(priority: .userInitiated) {
                    (i, try await KeyPair(
                        phrase: phrases,
                        network: Defaults.apiEndPoint.network,
                        derivablePath: .init(type: derivableType, walletIndex: i)
                    ))
                }
            }

            for try await(index, account) in group {
                accounts.append(
                    (index, .init(
                        derivablePath: .init(type: derivableType, walletIndex: index),
                        info: account,
                        amount: await self.cache.balanceCache[account.publicKey.base58EncodedString],
                        price: await self.cache.solPriceCache,
                        isBlured: false
                    ))
                )
            }

            return accounts.sorted(by: { $0.0 < $1.0 }).map(\.1)
        }
    }

    private func fetchSOLPrice() async throws {
        if await cache.solPriceCache != nil { return }

        try Task.checkCancellation()

        let solPrice = try await pricesFetcher.getCurrentPrices(coins: [.nativeSolana], toFiat: Defaults.fiat.code)
            .first?.value?.value ?? 0
        await cache.save(solPrice: solPrice)

        try Task.checkCancellation()

        if state == .loaded {
            let data = data.map { account -> DerivableAccount in
                var account = account
                account.price = solPrice
                return account
            }
            overrideData(by: data)
        }
    }

    private func fetchBalances(accounts: [String]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for account in accounts {
                group.addTask {
                    try await self.fetchBalance(account: account)
                }
                try Task.checkCancellation()
                for try await _ in group {}
            }
        }
    }

    private func fetchBalance(account: String) async throws {
        if await cache.balanceCache[account] != nil {
            return
        }

        try Task.checkCancellation()

        let amount = try await solanaAPIClient.getBalance(account: account, commitment: nil)
            .convertToBalance(decimals: 9)

        try Task.checkCancellation()
        await cache.save(account: account, amount: amount)

        try Task.checkCancellation()
        if state == .loaded {
            updateItem(
                where: { $0.info.publicKey.base58EncodedString == account },
                transform: { account in
                    var account = account
                    account.amount = amount
                    return account
                }
            )
        }
    }
    
    @discardableResult
    private func updateItem(where predicate: (DerivableAccount) -> Bool, transform: (DerivableAccount) -> DerivableAccount?) -> Bool {
        // modify items
        var itemsChanged = false
        if let index = data.firstIndex(where: predicate),
           let item = transform(data[index]),
           item != data[index]
        {
            itemsChanged = true
            var data = self.data
            data[index] = item
            overrideData(by: data)
        }
        
        return itemsChanged
    }
}

// MARK: - Analytics
extension DerivableAccountsViewModel {
    func logSelection(derivableType: DerivablePath.DerivableType) {
        analyticsManager.log(event: .recoveryDerivableAccountsPathSelected(path: DerivablePath(type: derivableType, walletIndex: 0).rawValue))
    }

    private func logRestoreClick() {
        analyticsManager.log(event: .recoveryRestoreClick)
    }

    private func logOpen() {
        analyticsManager.log(event: .recoveryDerivableAccountsOpen)
    }
}

// MARK: - List Helpers from old BEViewModel and BECollectionViewModel
private extension DerivableAccountsViewModel {
    func overrideData(by newData: [DerivableAccount]) {
        guard newData != data else { return }
        handleNewData(newData)
    }

    func reload() {
        flush()
        request(reload: true)
    }

    func flush() {
        data = []
        state = .initializing
        error = nil
    }

    func request(reload: Bool = false) {
        if reload {
            // cancel previous request
            cancelRequest()
        }

        state = .loading
        error = nil

        task = Task {
            do {
                let newData = try await createRequest()
                handleNewData(newData)
            } catch {
                if error is CancellationError {
                    return
                }
                handleError(error)
            }
        }
    }

    func cancelRequest() {
        task?.cancel()
    }

    func handleNewData(_ newData: [DerivableAccount]) {
        data = newData
        error = nil
        state = .loaded
    }

    func handleError(_ error: Error) {
        self.error = error
        state = .error
    }
}
