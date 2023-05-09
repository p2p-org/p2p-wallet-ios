//
//  HistoryServiceAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.05.2023.
//

import Combine
import Foundation
import History
import KeyAppBusiness
import KeyAppKitCore
import Send
import Wormhole

class HistoryServiceAggregator: DataAggregator {
    func transform(
        input: (
            history: [HistoryTransaction],
            tokens: Set<SolanaToken>,
            action: PassthroughSubject<NewHistoryAction, Never>
        )
    ) -> [RendableListHistoryTransactionItem] {
        let (history, tokens, action) = input

        let items = history
            .filter { trx -> Bool in
                switch trx.info {
                case .wormholeReceive, .wormholeSend, .createAccountIdempotent:
                    // Handle bridge receive and send and another aggregator.
                    return false
                default:
                    // Others history transaction will be handed here.
                    return true
                }
            }
            .map { trx -> RendableListHistoryTransactionItem in
                RendableListHistoryTransactionItem(trx: trx, allTokens: tokens) { [weak action] in
                    action?.send(.openHistoryTransaction(trx))
                }
            }

        return items
    }
}
