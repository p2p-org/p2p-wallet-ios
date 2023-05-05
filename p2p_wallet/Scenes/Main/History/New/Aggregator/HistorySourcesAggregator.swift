//
//  HistoryAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.05.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import History

class HistorySourceAggregator: DataAggregator {
    func transform(
        input: (
            mocks: [any RendableListTransactionItem],
            actions: [any UserAction],
            pendings: [PendingTransaction],
            sells: [RendableListHistoryTransactionItem],
            history: ListState<HistoryTransaction>,
            mintAddress: String?,
            tokens: Set<SolanaToken>
        )
    ) -> ListState<HistorySection> {
        let (mocks, actions, pendings, sells, history, mintAddress, tokens) = input

        let aggregatedPending = HistoryPendingTransactionAggregator()
            .transform(input: (pendings, mintAddress))
        
        

        /*

         // Phase 1: Merge pending transaction with history transaction
         let rendableTransactions: [any RendableListTransactionItem] = ListBuilder
             .merge(primary: history.data, secondary: others, by: \.id)

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
                 insertedItems = [.button(id: UUID().uuidString, title: L10n.tryAgain, action: { [weak self] in
                     self?.fetch()
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
          */

        return .init(
            status: history.status,
            data: [],
            fetchable: history.fetchable,
            error: history.error
        )
    }
}
