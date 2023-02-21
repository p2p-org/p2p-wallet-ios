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
import RxSwift
import Sell
import SolanaSwift
import TransactionParser

enum NewHistoryAction {
    case openParsedTransaction(ParsedTransaction)

    case openHistoryTransaction(HistoryTransaction)

    case openSellTransaction(SellDataServiceTransaction)

    case openPendingTransaction(PendingTransaction)
}

class NewHistoryViewModel: BaseViewModel, ObservableObject {
    // Subjects

    let actionSubject: PassthroughSubject<NewHistoryAction, Never>

    // State

    @Published private var pendingTransactions: [any RendableListTransactionItem] = []

    @Published private var sellTransansactions: [any RendableListOfframItem] = []

    let historyTransactions: AsyncList<any RendableListTransactionItem>

    // Output

    var sections: [NewHistoryListSection] {
        // Phase 1: Merge pending transaction with history transaction
        let rendableTransactions: [any RendableListTransactionItem] = ListBuilder.merge(primary: historyTransactions.state.data, secondary: pendingTransactions, by: \.id)

        // Phase 2: Split transactions by date
        var sections: [NewHistoryListSection] = ListBuilder.aggregate(list: rendableTransactions, by: \.date) { title, items in
            .init(title: title, items: items.map { .rendableTransaction($0) })
        }

        // Phase 3: Join sell transactions at beginning
        if !sellTransansactions.isEmpty {
            sections.insert(
                .init(title: "", items: sellTransansactions.map { trx in .rendableOffram(trx) }),
                at: 0
            )
        }

        // Phase 4: Add skeleton or error button
        if let lastSection = sections.popLast() {
            var insertedItems: [NewHistoryItem] = []

            if historyTransactions.state.fetchable {
                insertedItems = .generatePlaceholder(n: 1) + [.fetch(id: UUID().uuidString)]
            }

            if historyTransactions.state.error != nil {
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
        if historyTransactions.state.status == .fetching && sections.isEmpty {
            return [
                .init(title: "", items: .generatePlaceholder(n: 7))
            ]
        }

        return sections
    }

    init(mock: [any RendableListTransactionItem]) {
        // Init service
        let actionSubject: PassthroughSubject<NewHistoryAction, Never> = .init()
        self.actionSubject = actionSubject

        // Build history
        historyTransactions = .init(sequence: mock.async.eraseToAnyAsyncSequence())
    }

    init(
        provider: KeyAppHistoryProvider = Resolver.resolve(),
        userWalletManager: UserWalletManager = Resolver.resolve(),
        tokensRepository: TokensRepository = Resolver.resolve(),
        sellDataService: any SellDataService = Resolver.resolve(),
        pendingTransactionService: TransactionHandlerType = Resolver.resolve(),
        mint: String? = nil
    ) {
        // Init services and repositories
        let repository = NewHistoryServiceRepository(provider: provider)

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

        historyTransactions = .init(sequence: sequence, id: \.id)

        super.init()

        // Ignore showing sell and pending trx
        if mint == nil {
            // Listen sell service
            sellDataService.transactionsPublisher
                .sink { [weak self] transactions in
                    self?.sellTransansactions = transactions.map { trx in
                        SellRendableListOfframItem(trx: trx) { [weak actionSubject] in
                            actionSubject?.send(.openSellTransaction(trx))
                        }
                    }
                }
                .store(in: &subscriptions)

            // Listen pending transactions
            pendingTransactionService.observePendingTransactions()
                .sink { [weak self] transactions in
                    self?.pendingTransactions = transactions.map { [weak actionSubject] trx in
                        RendableListPendingTransactionItem(trx: trx) {
                            actionSubject?.send(.openPendingTransaction(trx))
                        }
                    }
                }
                .store(in: &subscriptions)
        }

        // Listen history transactions
        historyTransactions.listen(target: self, in: &subscriptions)
    }

    func reload() async throws {
        historyTransactions.reset()
        try await historyTransactions.fetch()?.value
    }

    func fetch() {
        historyTransactions.fetch()
    }
}
