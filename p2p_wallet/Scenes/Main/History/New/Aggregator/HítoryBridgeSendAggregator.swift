//
//  HistoryBridgeClaimAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 08.05.2023.
//

import Combine
import Foundation
import History
import KeyAppBusiness
import KeyAppKitCore
import Send
import Wormhole

/// Bridge send aggregator.
///
/// Showing send user action bases on history transactions.
/// If send action is in progressing or update time is less 5 minute ago, then we also display it because history
/// service maybe not ready to display it.
class HistoryBridgeSendAggregator: DataAggregator {
    func transform(
        input: (
            history: [HistoryTransaction],
            userActions: [any UserAction],
            mint: String?,
            action: PassthroughSubject<NewHistoryAction, Never>
        )
    ) -> [any RendableListTransactionItem] {
        let (history, userActions, mint, action) = input

        var items: [RendableListUserActionTransactionItem] = []
        var handedBridgeServiceKeys: [String] = []

        let userActionSends = userActions.compactMap { $0 as? WormholeSendUserAction }
        let historySends = history.filter {
            if case .wormholeSend = $0.info {
                return true
            } else {
                return false
            }
        }

        // Build items from history.
        for historyItem in historySends {
            if case let .wormholeSend(data) = historyItem.info {
                let send = userActionSends.first { $0.id == data.bridgeServiceKey }

                if let send {
                    let item = RendableListUserActionTransactionItem(userAction: send) { [weak action] in
                        action?.send(.openUserAction(send))
                    }

                    handedBridgeServiceKeys.append(data.bridgeServiceKey)
                    items.append(item)
                } else {
                    continue
                }
            }
        }

        // Build pending and finish (not older 5 minute) claims.
        let filteredClaims = userActionSends.filter { send in
            if let mint {
                if send.amount.token.tokenPrimaryKey != mint {
                    return false
                } else if send.amount.token.tokenPrimaryKey == "native", mint != SolanaToken.nativeSolana.address {
                    return false
                }
            }

            // Claim is already handed in prev step
            if
                handedBridgeServiceKeys.contains(send.id)
            {
                return false
            }

            switch send.status {
            case .pending, .processing:
                return true
            case .error, .ready:
                return Date().timeIntervalSince(send.updatedDate) <= 60 * 5
            }
        }

        for claim in filteredClaims {
            let item = RendableListUserActionTransactionItem(userAction: claim) { [weak action] in
                action?.send(.openUserAction(claim))
            }

            items.append(item)
        }

        return items
    }
}
