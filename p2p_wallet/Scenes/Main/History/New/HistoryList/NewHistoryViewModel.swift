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
import AsyncAlgorithms

enum NewHistoryAction {
    case openParsedTransaction(ParsedTransaction)

    case openHistoryTransaction(HistoryTransaction)

    case openSellTransaction(SellDataServiceTransaction)

    case openPendingTransaction(PendingTransaction)
}

class NewHistoryViewModel: BaseViewModel, ObservableObject {
    // State

    @Published private var pendingTransactions: [any RendableListTransactionItem] = []

    @Published private var sellTransansactions: [any RendableListOfframItem] = []

    @Published private(set) var historyTransactions: ListState<any RendableListTransactionItem>

    // Output

    var sections: [NewHistoryListSection] {
        buildSection()
    }

    let actionSubject: PassthroughSubject<NewHistoryAction, Never>
    
    init(mock: [any RendableListTransactionItem]) {
        // Init service
        let actionSubject: PassthroughSubject<NewHistoryAction, Never> = .init()
        self.actionSubject = actionSubject
        
        // Build history
        historyTransactions = .init(
            status: .ready,
            data: mock,
            fetchable: true,
            error: nil
        )
        
        self.fetch = {}
        self.reload = {}
        
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
        let historyTransactionsAsyncList: AsyncList<any RendableListTransactionItem> = .init(
            sequence: repository
                .getAll(account: userWalletManager.wallet?.account, mint: mint)
                .map { trx in
                    await RendableListHistoryTransactionItem(
                        trx: trx,
                        allTokens: try tokensRepository.getTokensList(useCache: true),
                        onTap: { [weak actionSubject] in
                            actionSubject?.send(.openHistoryTransaction(trx))
                        }
                    )
                }
                .eraseToAnyAsyncSequence()
        )
        
        fetch =  {
            historyTransactionsAsyncList.fetch()
        }
        
        reload = {
            historyTransactionsAsyncList.reset()
            historyTransactionsAsyncList.fetch()
        }
        
        historyTransactions = .init()
        
        super.init()

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

        // Listen history transactions
        historyTransactionsAsyncList.$state
            .assign(to: &$historyTransactions)
    }

    var reload: () -> Void

    var fetch: () -> Void

    func buildSection() -> [NewHistoryListSection] {
        // Phase 1: Merge pending transaction with history transaction

        let filtedPendingTransaction = pendingTransactions.filter { pendingTransaction in
            !historyTransactions.data.contains { historyTransaction in
                historyTransaction.id == pendingTransaction.id
            }
        }

        let rendableTransactions: [any RendableListTransactionItem] = filtedPendingTransaction + historyTransactions.data

        // Phase 2: Split transactions by date
        let dictionary = Dictionary(grouping: rendableTransactions) { transaction -> Date in
            Calendar.current.startOfDay(for: transaction.date)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.shared

        var result = dictionary.keys.sorted().reversed()
            .map { key in
                let items = dictionary[key]?.map { trx -> NewHistoryItem in
                    .rendableTransaction(trx)
                }

                return NewHistoryListSection(title: dateFormatter.string(from: key), items: items ?? [])
            }

        // Phase 3: Insert sell transactions at beginning
        if !sellTransansactions.isEmpty {
            result.insert(
                .init(
                    title: "",
                    items: sellTransansactions.map { trx in .rendableOffram(trx) }
                ),
                at: 0
            )
        }

        // Phase 4: Add skeleton
        if let lastSection = result.popLast() {
            var insertedItems: [NewHistoryItem] = []

            if historyTransactions.fetchable {
                insertedItems = .generatePlaceholder(n: 1) + [.fetch(id: UUID().uuidString)]
            }

            if historyTransactions.error != nil {
                insertedItems = [.button(id: UUID().uuidString, title: L10n.tryAgain, action: { [weak self] in self?.fetch() })]
            }

            result.append(
                .init(
                    title: lastSection.title,
                    items: lastSection.items + insertedItems
                )
            )
        }

        // Phase 5: Or replace with skeletons in first load
        if historyTransactions.status == .fetching && result.isEmpty {
            return [
                .init(title: "", items: .generatePlaceholder(n: 7))
            ]
        }

        return result
    }
}
