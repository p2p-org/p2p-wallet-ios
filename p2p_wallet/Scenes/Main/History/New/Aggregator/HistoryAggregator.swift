//
//  HistoryAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.05.2023.
//

import Combine
import Foundation
import History
import KeyAppBusiness
import KeyAppKitCore
import Sell
import Send
import Wormhole

class HistoryAggregator: DataAggregator {
    struct Input {
        let mocks: [any RendableListTransactionItem]
        let userActions: [any UserAction]
        let pendings: [PendingTransaction]
        let sells: [SellDataServiceTransaction]
        let history: ListState<HistoryTransaction>
        let mintAddress: String?
        let tokens: Set<SolanaToken>
        let action: PassthroughSubject<NewHistoryAction, Never>
        let fetch: () -> Void
    }

    func transform(input: Input) -> ListState<HistorySection> {
        let mocks = input.mocks
        let userActions = input.userActions
        let pendings = input.pendings
        let sells = input.sells
        let history = input.history
        let mintAddress = input.mintAddress
        let tokens = input.tokens
        let action = input.action
        let fetch = input.fetch

        let pendingItems: [any RendableListTransactionItem] = HistoryPendingTransactionAggregator()
            .transform(input: (pendings, mintAddress, action))

        let historyItems: [any RendableListTransactionItem] = HistoryServiceAggregator()
            .transform(input: (history.data, tokens, action))

        let claimItems: [any RendableListTransactionItem] = HistoryBridgeClaimAggregator()
            .transform(input: (history.data, userActions, mintAddress, action))

        let sendItems: [any RendableListTransactionItem] = HistoryBridgeSendAggregator()
            .transform(input: (history.data, userActions, mintAddress, action))

        // Phase 1: Merge pending transaction with history transaction
        let primary: [any RendableListTransactionItem] = historyItems + claimItems + sendItems + mocks

        let rendableTransactions: [any RendableListTransactionItem] = ListBuilder
            .merge(primary: primary, secondary: pendingItems, by: \.id)

        // Phase 2: Split transactions by date
        var sections: [HistorySection] = ListBuilder
            .aggregate(list: rendableTransactions, by: \.date) { title, items in
                .init(title: title, items: items.map { .rendableTransaction($0) })
            }

        // Phase 3: Join sell transactions at beginning
        if !sells.isEmpty {
            sections.insert(
                .init(
                    title: "", items: sells
                        .map { [weak action] trx in
                            SellRendableListOfframItem(trx: trx) { [weak action] in
                                action?.send(.openSellTransaction(trx))
                            }
                        }
                        .map { trx in .rendableOffram(trx) }
                ),
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
                insertedItems = [.button(id: UUID().uuidString, title: L10n.tryAgain, action: { [weak self] in
                    fetch()
                })]
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
                .init(title: "", items: .generatePlaceholder(n: 7)),
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
