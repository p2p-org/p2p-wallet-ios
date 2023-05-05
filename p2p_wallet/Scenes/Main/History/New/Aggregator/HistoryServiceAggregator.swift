//
//  HistoryServiceAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.05.2023.
//

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
            actions: [any UserAction],
            tokens: Set<SolanaToken>
        )
    ) -> [any RendableListTransactionItem] {
        let (history, actions, tokens) = input

        let claimActions = actions
            .compactMap { $0 as? WormholeClaimUserAction }
            .map(\.claimKey)

        let sendActions = actions
            .compactMap { $0 as? WormholeSendUserAction }
            .map(\.id)

        var items = history
            .filter { trx -> Bool in
                switch trx.info {
                case let .wormholeReceive(data):
                    return claimActions.contains(data.bridgeServiceKey) == false
                case let .wormholeSend(data):
                    return sendActions.contains(data.bridgeServiceKey) == false
                default:
                    return true
                }
            }
            .map { trx -> any RendableListTransactionItem in
                RendableListHistoryTransactionItem(trx: trx, allTokens: tokens)
            }
        
        return items
    }

//    /// Aggregate claim transaction
//    /// - Parameters:
//    ///   - trx: claim transaction from history service
//    ///   - info: receive info
//    ///   - actions: all claim user actions
//    func aggregateClaimTransaction(trx: HistoryTransaction, info: WormholeReceive, actions: [WormholeClaimUserAction])
//    -> HistoryTransaction? {
//
//    }
}
