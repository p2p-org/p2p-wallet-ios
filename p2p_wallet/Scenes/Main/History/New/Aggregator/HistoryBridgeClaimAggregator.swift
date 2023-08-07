import Combine
import Foundation
import History
import KeyAppBusiness
import KeyAppKitCore
import Send
import Wormhole

/// Bridge claim aggregator.
///
/// Showing claim user action bases on history transactions.
/// If claim action is in progressing or update time is less 5 minute ago, then we also display it because history
/// service maybe not ready to display it.
class HistoryBridgeClaimAggregator: DataAggregator {
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

        var userActionClaims = userActions.compactMap { $0 as? WormholeClaimUserAction }
        let historyClaims = history.filter {
            if case .wormholeReceive = $0.info {
                return true
            } else {
                return false
            }
        }

        if let mint {
            userActionClaims = userActionClaims.filter { action in
                let bridge = SupportedToken.bridges.first { $0.solAddress == mint }
                if let bridge {
                    switch action.token.contractType {
                    case .native:
                        return bridge.ethAddress == nil
                    case let .erc20(contract: address):
                        return bridge.ethAddress == address.hex(eip55: false)
                    }
                } else {
                    return false
                }
            }
        }

        // Build items from history.
        for historyItem in historyClaims {
            if case let .wormholeReceive(data) = historyItem.info {
                var claim = userActionClaims.first { $0.claimKey == data.bridgeServiceKey }

                if var claim {
                    claim.solanaTransaction = historyItem.signature
                    let item = RendableListUserActionTransactionItem(userAction: claim) { [weak action] in
                        action?.send(.openUserAction(claim))
                    }

                    handedBridgeServiceKeys.append(data.bridgeServiceKey)
                    items.append(item)
                } else {
                    continue
                }
            }
        }

        // Build pending and finish (not older 5 minute) claims.
        let filteredClaims = userActionClaims.filter { claim in
            // Claim is already handed in prev step
            if
                let claimKey = claim.claimKey,
                handedBridgeServiceKeys.contains(claimKey)
            {
                return false
            }

            switch claim.status {
            case .pending, .processing:
                return true
            case .error, .ready:
                return Date().timeIntervalSince(claim.updatedDate) <= 60 * 5
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
