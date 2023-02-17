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
import SolanaSwift
import TransactionParser

enum NewHistoryAction {
    case openParsedTransaction(ParsedTransaction)

    case openHistoryTransaction(HistoryTransaction)
}

class NewHistoryViewModel: BaseViewModel, ObservableObject {
    // Services

    private let repository: NewHistoryServiceRepository

    // State

    let historyTransactionList: ListAdapter<AnyAsyncSequence<RendableHistoryTransactionListItem>>

    let actionSubject: PassthroughSubject<NewHistoryAction, Never>

    // Output

    var sections: [NewHistorySection] {
        buildSection()
    }

    init(
        provider: KeyAppHistoryProvider = Resolver.resolve(),
        userWalletManager: UserWalletManager = Resolver.resolve(),
        tokensRepository: TokensRepository = Resolver.resolve(),
        mint: String? = nil
    ) {
        // Init services and repositories
        repository = NewHistoryServiceRepository(provider: provider)

        let actionSubject: PassthroughSubject<NewHistoryAction, Never> = .init()
        self.actionSubject = actionSubject

        // Setup list adaptor
        historyTransactionList = .init(
            sequence: repository
                .getAll(account: userWalletManager.wallet?.account, mint: mint)
                .map { trx in
                    await RendableHistoryTransactionListItem(
                        trx: trx,
                        allTokens: try tokensRepository.getTokensList(useCache: true),
                        onTap: { [weak actionSubject] () in
                            actionSubject?.send(.openHistoryTransaction(trx))
                        }
                    )
                }
                .eraseToAnyAsyncSequence()
        )

        super.init()

        // Emit changes to model
        historyTransactionList.listen(target: self, in: &subscriptions)
    }

    func reload() {
        historyTransactionList.reset()
        historyTransactionList.fetch()
    }

    func fetch() {
        historyTransactionList.fetch()
    }

    func buildSection() -> [NewHistorySection] {
        // Phase 1: Split history transaction into section by date
        let dictionary = Dictionary(grouping: historyTransactionList.state.data) { transaction -> Date in
            Calendar.current.startOfDay(for: transaction.date)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.shared

        var result = dictionary.keys.sorted().reversed()
            .map { key in
                let items = dictionary[key]?.map { trx -> NewHistoryItem in
                    .rendable(trx)
                }

                return NewHistorySection(title: dateFormatter.string(from: key), items: items ?? [])
            }

        // Phase 2: Add skeleton
        if let lastSection = result.popLast() {
            var insertedItems: [NewHistoryItem] = []

            if historyTransactionList.state.fetchable {
                insertedItems = .generatePlaceholder(n: 1) + [.fetch(id: UUID().uuidString)]
            }

            if historyTransactionList.state.error != nil {
                insertedItems = [.button(id: UUID().uuidString, title: L10n.tryAgain, action: { [weak self] in self?.fetch() })]
            }

            result.append(
                .init(
                    title: lastSection.title,
                    items: lastSection.items + insertedItems
                )
            )
        }

        // Phase 2: Or replace with skeletons in first load
        if historyTransactionList.state.status == .fetching && historyTransactionList.state.data.isEmpty {
            return [
                .init(title: "", items: .generatePlaceholder(n: 7))
            ]
        }

        print(historyTransactionList.state.error)
        return result
    }
}
