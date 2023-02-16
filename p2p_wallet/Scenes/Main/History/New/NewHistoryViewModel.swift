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
    case openDetailByParsedTransaction(ParsedTransaction)
}

class NewHistoryViewModel: BaseViewModel, ObservableObject {
    // Services

    private let repository: NewHistoryServiceRepository

    // State

    let historyTransactionList: ListAdapter<NewHistoryServiceRepository.ItemSequence>

    var allTokens: [Token] = []

    let actionSubject = PassthroughSubject<NewHistoryAction, Never>()

    // Output

    var sections: [NewHistorySection] {
        buildSection()
    }

    init(
        provider: KeyAppHistoryProvider = Resolver.resolve(),
        userWalletManager: UserWalletManager = Resolver.resolve(),
        mint: String? = nil
    ) {
        // Init services and repositories
        repository = NewHistoryServiceRepository(provider: provider)

        // Setup list adaptor
        historyTransactionList = .init(sequence: repository.getAll(account: userWalletManager.wallet?.account, mint: mint))

        super.init()

        // Emit changes to model
        historyTransactionList.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }.store(in: &subscriptions)
//        historyTransactionList.listen(target: self, in: &subscriptions)
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
                    .rendable(RendableHistoryTransactionListItem(trx: trx, allTokens: allTokens))
                }

                return NewHistorySection(title: dateFormatter.string(from: key), items: items ?? [])
            }

        // Phase 2: Add skeleton
        if historyTransactionList.state.fetchable {
            if let lastSection = result.popLast() {
                result.append(
                    .init(
                        title: lastSection.title,
                        items: lastSection.items + .generatePlaceholder(n: 1)
                    )
                )
            }
        }

        if historyTransactionList.state.status == .fetching && historyTransactionList.state.data.isEmpty {
            return [
                .init(title: "", items: .generatePlaceholder(n: 7))
            ]
        }

        return result
    }

    func onTap(item: any NewHistoryRendableItem) {
//        if let item = item as? RendableParsedTransaction {
//            actionSubject.send(.openDetailByParsedTransaction(item.trx))
//        }
    }
}
