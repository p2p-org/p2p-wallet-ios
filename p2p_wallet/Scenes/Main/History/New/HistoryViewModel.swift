//
//  NewHistoryViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 01.02.2023.
//

import Combine
import Foundation
import History
import Resolver
import Sell
import SolanaSwift
import TransactionParser

enum NewHistoryAction {
    case openParsedTransaction(ParsedTransaction)

    case openHistoryTransaction(HistoryTransaction)

    case openSellTransaction(SellDataServiceTransaction)

    case openPendingTransaction(PendingTransaction)

    case openReceive

    case openBuy
    
    case openSentViaLinkHistoryView
}

class HistoryViewModel: BaseViewModel, ObservableObject {
    // Subjects

    let actionSubject: PassthroughSubject<NewHistoryAction, Never>

    let history: AsyncList<any RendableListTransactionItem>

    // State

    @Published var output: ListState<HistorySection> = .init()
    @Published var sendViaLinkTransactions: [SendViaLinkTransactionInfo] = []
    
    let showSendViaLinkTransaction: Bool
    
    // Dependency

    private var sellDataService: (any SellDataService)?
    @Injected private var sendViaLinkStorage: SendViaLinkStorage

    init(mock: [any RendableListTransactionItem]) {
        // Init service
        let actionSubject: PassthroughSubject<NewHistoryAction, Never> = .init()
        self.actionSubject = actionSubject

        // Build history
        history = .init(sequence: mock.async.eraseToAnyAsyncSequence())

        self.showSendViaLinkTransaction = false
        super.init()

        history
            .$state
            .map { self.buildOutput(history: $0) }
            .receive(on: RunLoop.main)
            .sink { self.output = $0 }
            .store(in: &subscriptions)
    }

    init(
        provider: KeyAppHistoryProvider = Resolver.resolve(),
        userWalletManager: UserWalletManager = Resolver.resolve(),
        tokensRepository: TokensRepository = Resolver.resolve(),
        mint: String
    ) {
        // Init services and repositories
        let repository = HistoryRepository(provider: provider)

        let actionSubject: PassthroughSubject<NewHistoryAction, Never> = .init()
        self.actionSubject = actionSubject

        // Setup list adaptor
        let sequence = repository
            .getAll(account: userWalletManager.wallet?.account, mint: mint)
            .map { trx -> any RendableListTransactionItem in
                await RendableListHistoryTransactionItem(
                    trx: trx,
                    allTokens: try tokensRepository.getTokensList(useCache: true),
                    onTap: { [weak actionSubject] in
                        actionSubject?.send(.openHistoryTransaction(trx))
                    }
                )
            }
            .eraseToAnyAsyncSequence()

        history = .init(sequence: sequence, id: \.id)
        
        self.showSendViaLinkTransaction = false
        super.init()

        history
            .$state
            .receive(on: DispatchQueue.global(qos: .background))
            .map { self.buildOutput(history: $0) }
            .receive(on: RunLoop.main)
            .sink { self.output = $0 }
            .store(in: &subscriptions)
        
        bind()
    }

    init(
        provider: KeyAppHistoryProvider = Resolver.resolve(),
        userWalletManager: UserWalletManager = Resolver.resolve(),
        tokensRepository: TokensRepository = Resolver.resolve(),
        sellDataService: any SellDataService = Resolver.resolve(),
        pendingTransactionService: TransactionHandlerType = Resolver.resolve()
    ) {
        // Init services and repositories
        let repository = HistoryRepository(provider: provider)

        let actionSubject: PassthroughSubject<NewHistoryAction, Never> = .init()
        self.actionSubject = actionSubject
        self.sellDataService = sellDataService


        // Setup list adaptor
        let sequence = repository
            .getAll(account: userWalletManager.wallet?.account, mint: nil)
            .map { trx -> any RendableListTransactionItem in
                await RendableListHistoryTransactionItem(
                    trx: trx,
                    allTokens: try tokensRepository.getTokensList(useCache: true),
                    onTap: { [weak actionSubject] in
                        actionSubject?.send(.openHistoryTransaction(trx))
                    }
                )
            }
            .eraseToAnyAsyncSequence()

        history = .init(sequence: sequence, id: \.id)

        // Listen sell service
        let sells = sellDataService.transactionsPublisher
            .map { transactions in
                transactions.map { trx in
                    SellRendableListOfframItem(trx: trx) { [weak actionSubject] in
                        actionSubject?.send(.openSellTransaction(trx))
                    }
                }
            }

        // Listen pending transactions
        
        // Using this code if need to listen pending transactions
        let pendings = pendingTransactionService.observePendingTransactions()
            .map { transactions in
                transactions
                    .filter { pendingTransation in
                        switch pendingTransation.rawTransaction {
                        case let trx as SendTransaction where trx.isSendingViaLink:
                            return false
                        default:
                            return true
                        }
                    }
                    .map { [weak actionSubject] trx in
                        RendableListPendingTransactionItem(trx: trx) {
                            actionSubject?.send(.openPendingTransaction(trx))
                        }
                    }
            }

        self.showSendViaLinkTransaction = true
        super.init()

        // Build output
        history
            .$state
            .combineLatest(sells, pendings)
            .map(buildOutput)
            .receive(on: RunLoop.main)
            .sink { self.output = $0 }
            .store(in: &subscriptions)
        
        bind()
    }

    func reload() async throws {
        history.reset()
        try await history.fetch()?.value
        await sellDataService?.update()
    }

    func fetch() {
        history.fetch()
        Task {
            await sellDataService?.update()
        }
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
    }

    private func buildOutput(
        history: ListState<any RendableListTransactionItem>,
        sells: [any RendableListOfframItem] = [],
        pendings: [any RendableListTransactionItem] = []
    ) -> ListState<HistorySection> {
        // Phase 1: Merge pending transaction with history transaction
        let rendableTransactions: [any RendableListTransactionItem] = ListBuilder.merge(primary: history.data, secondary: pendings, by: \.id)

        // Phase 2: Split transactions by date
        var sections: [HistorySection] = ListBuilder.aggregate(list: rendableTransactions, by: \.date) { title, items in
            .init(title: title, items: items.map { .rendableTransaction($0) })
        }

        // Phase 3: Join sell transactions at beginning
        if !sells.isEmpty {
            sections.insert(
                .init(title: "", items: sells.map { trx in .rendableOffram(trx) }),
                at: 0
            )
        }

        // Phase 4: Add skeleton or error button
        if let lastSection = sections.popLast() {
            var insertedItems: [NewHistoryItem] = []

            if history.fetchable {
                insertedItems = .generatePlaceholder(n: 1) + [.fetch(id: UUID().uuidString)]
            }

            if history.error != nil {
                insertedItems = [.button(id: UUID().uuidString, title: L10n.tryAgain, action: { [weak self] in self?.fetch() })]
            }

            sections.append(
                .init(
                    title: lastSection.title,
                    items: lastSection.items + insertedItems
                )
            )
        }

        // Phase 5: Or replace with skeletons in first load
        if history.status == .fetching && sections.isEmpty {
            sections = [
                .init(title: "", items: .generatePlaceholder(n: 7))
            ]
        }

        return .init(
            status: history.status,
            data: sections,
            fetchable: history.fetchable,
            error: history.error
        )
    }
}
