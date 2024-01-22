import AnalyticsManager
import Combine
import Foundation
import History
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Sell
import SolanaSwift

enum NewHistoryAction {
    case openHistoryTransaction(HistoryTransaction)

    case openSellTransaction(SellDataServiceTransaction)

    case openPendingTransaction(PendingTransaction)

    case openUserAction(any UserAction)

    case openReceive

    case openBuy

    case openSwap(SolanaAccount?, SolanaAccount?)

    case openSentViaLinkHistoryView
}

class HistoryViewModel: BaseViewModel, ObservableObject {
    // MARK: - Subjects

    let actionSubject: PassthroughSubject<NewHistoryAction, Never>

    let history: AsyncList<HistoryTransaction>

    @Published var tokens: Set<SolanaToken> = []

    // MARK: - View Input

    /// General output list. (Normally from history items)
    @Published var output = ListState<HistorySection>()

    /// Send via link section.
    @Published var sendViaLinkTransactions = [SendViaLinkTransactionInfo]() {
        didSet {
            if sendViaLinkTransactions.count == 1 {
                linkTransactionsTitle = "1 \(L10n.transaction.lowercased())"
            } else {
                linkTransactionsTitle = L10n.transactions(sendViaLinkTransactions.count)
            }
        }
    }

    /// Send via link title
    @Published var linkTransactionsTitle = ""

    /// Feature toggle
    let showSendViaLinkTransaction: Bool

    // MARK: - Dependency

    private var sellDataService: (any SellDataService)?
    @Injected private var sendViaLinkStorage: SendViaLinkStorage
    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Init

    init(mock: [any RendableListTransactionItem]) {
        // Init service
        let actionSubject: PassthroughSubject<NewHistoryAction, Never> = .init()
        self.actionSubject = actionSubject

        // Build history
        history = .init(sequence: [].async.eraseToAnyAsyncSequence())

        showSendViaLinkTransaction = false
        super.init()

        output = .init(
            status: .ready,
            data: [.init(title: "Today", items: mock.map { .rendableTransaction($0) })],
            fetchable: false,
            error: nil
        )
    }

    init(
        provider: KeyAppHistoryProvider = Resolver.resolve(),
        userWalletManager: UserWalletManager = Resolver.resolve(),
        tokensRepository: SolanaTokensService = Resolver.resolve(),
        pendingTransactionService: TransactionHandlerType = Resolver.resolve(),
        userActionService: UserActionService = Resolver.resolve(),
        mint: String
    ) {
        // Init services and repositories
        let repository = HistoryRepository(provider: provider)

        let actionSubject: PassthroughSubject<NewHistoryAction, Never> = .init()
        self.actionSubject = actionSubject

        // Setup list adaptor
        let sequence = repository
            .getAll(account: userWalletManager.wallet?.account, mint: mint)
            .eraseToAnyAsyncSequence()
        history = .init(sequence: sequence, id: \.id)

        showSendViaLinkTransaction = false
        super.init()

        // Listen pending transactions
        let pendingTransactions = HistoryViewModelAggregator.pendingTransaction(
            pendingTransactionService: pendingTransactionService,
            actionSubject: actionSubject,
            mint: mint
        )

        // Build output
        let aggregator = HistoryAggregator()
        Publishers
            .CombineLatest3(
                history.$state,
                pendingTransactionService.observePendingTransactions(),
                userActionService.actions
            )
            .combineLatest(HistoryDebug.shared.$mockItems, $tokens)
            .map { firstStream, mocks, tokens in
                let (history, pendings, userActions) = firstStream

                return aggregator.transform(
                    input: .init(
                        mocks: mocks,
                        userActions: userActions,
                        pendings: pendings,
                        sells: [],
                        history: history,
                        mintAddress: mint,
                        tokens: tokens,
                        action: actionSubject,
                        fetch: self.fetch
                    )
                )
            }
            .receive(on: RunLoop.main)
            .sink { self.output = $0 }
            .store(in: &subscriptions)

        Task {
            tokens = try await Set(tokensRepository.all().values)
        }

        bind()
        fetch()
    }

    init(
        provider: KeyAppHistoryProvider = Resolver.resolve(),
        userWalletManager: UserWalletManager = Resolver.resolve(),
        tokensRepository: SolanaTokensService = Resolver.resolve(),
        sellDataService: any SellDataService = Resolver.resolve(),
        pendingTransactionService: TransactionHandlerType = Resolver.resolve(),
        userActionService: UserActionService = Resolver.resolve()
    ) {
        // Init services and repositories
        let repository = HistoryRepository(provider: provider)

        let actionSubject: PassthroughSubject<NewHistoryAction, Never> = .init()
        self.actionSubject = actionSubject
        self.sellDataService = sellDataService
        showSendViaLinkTransaction = true

        // Setup list adaptor
        let sequence = repository
            .getAll(account: userWalletManager.wallet?.account, mint: nil)
            .eraseToAnyAsyncSequence()
        history = .init(sequence: sequence, id: \.id)

        super.init()

        // Build output
        let aggregator = HistoryAggregator()
        Publishers
            .CombineLatest4(
                history.$state,
                pendingTransactionService.observePendingTransactions(),
                userActionService.actions,
                sellDataService.transactionsPublisher
            )
            .combineLatest(HistoryDebug.shared.$mockItems, $tokens)
            .map { firstStream, mocks, tokens in
                let (history, pendings, userActions, sells) = firstStream

                return aggregator.transform(
                    input: .init(
                        mocks: mocks,
                        userActions: userActions,
                        pendings: pendings,
                        sells: sells,
                        history: history,
                        mintAddress: nil,
                        tokens: tokens,
                        action: actionSubject,
                        fetch: self.fetch
                    )
                )
            }
            .receive(on: RunLoop.main)
            .sink { self.output = $0 }
            .store(in: &subscriptions)

        Task {
            tokens = try await Set(tokensRepository.all().values)
        }

        bind()
        fetch()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View Output

    func onAppear() {
        let withSentViaLink = showSendViaLinkTransaction && !sendViaLinkTransactions.isEmpty
        analyticsManager.log(event: .historyOpened(sentViaLink: withSentViaLink))

        fetch()
    }

    func reload() async throws {
        history.reset()
        try await history.fetch()?.value
        await sellDataService?.update(region: nil)
    }

    func fetch() {
        history.fetch()
        Task {
            await sellDataService?.update(region: nil)
        }
    }

    func sentViaLinkClicked() {
        analyticsManager.log(event: .historyClickBlockSendViaLink)
        actionSubject.send(.openSentViaLinkHistoryView)
    }

    // MARK: - Helpers

    private func bind() {
        // send via link
        sendViaLinkStorage.transactionsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] transactionInfos in
                self?.sendViaLinkTransactions = transactionInfos
            }
            .store(in: &subscriptions)

        NotificationCenter.default.addObserver(
            forName: HistoryAppdelegateService.shouldUpdateHistory.name,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task {
                try await self?.reload()
            }
        }
    }
}
