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
    typealias List = ListAdapter<HistoryTransaction, NewHistoryServiceRepository.AsyncIterator>

    // Services

    private var userWalletManager: UserWalletManager

    private var repository: NewHistoryServiceRepository

    @Published private var list: List

    // State

    var listState: List.State { list.state }

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
        repository = NewHistoryServiceRepository(provider: provider)
        self.userWalletManager = userWalletManager

        let userWalletManager: UserWalletManager = Resolver.resolve()
        list = .init(iterator: repository.getAll(account: userWalletManager.wallet?.account, mint: mint))

        super.init()

        list.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }.store(in: &subscriptions)
    }

    func fetchMore() async {
        list.fetch()
    }

    func buildSection() -> [NewHistorySection] {
        let dictionary = Dictionary(grouping: listState.data) { transaction -> Date in
            Calendar.current.startOfDay(for: transaction.date)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.shared

        let result = dictionary.keys.sorted().reversed()
            .map { key in
                let items = dictionary[key]?.map { trx -> NewHistoryItem in
                    .rendable(RendableHistoryTransactionListItem(trx: trx, allTokens: allTokens))
                }

                return NewHistorySection(title: dateFormatter.string(from: key), items: items ?? [])
            }

        return result
    }

    func onTap(item: any NewHistoryRendableItem) {
//        if let item = item as? RendableParsedTransaction {
//            actionSubject.send(.openDetailByParsedTransaction(item.trx))
//        }
    }
}
