//
//  PendingTransactionAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.05.2023.
//

import Combine
import Foundation
import KeyAppKitCore

class HistoryPendingTransactionAggregator: DataAggregator {
    func transform(
        input: (
            pendings: [PendingTransaction],
            mint: String?,
            action: PassthroughSubject<NewHistoryAction, Never>
        )
    ) -> [any RendableListTransactionItem] {
        let (pendings, mint, action) = input

        return pendings
            .filter { pendingTransation in
                // filter by transaction type
                switch pendingTransation.rawTransaction {
                case let trx as SendTransaction where trx.isSendingViaLink:
                    return false
                default:
                    return true
                }
            }
            .filter { pendingTransaction in
                // filter by mint
                guard let mint else { return true }
                switch pendingTransaction.rawTransaction {
                case let transaction as SendTransaction:
                    return transaction.walletToken.mintAddress == mint
                case let transaction as SwapRawTransactionType:
                    return transaction.sourceWallet.mintAddress == mint ||
                        transaction.destinationWallet.mintAddress == mint
                case let transaction as ClaimSentViaLinkTransaction:
                    return transaction.claimableTokenInfo.mintAddress == mint
                default:
                    return false
                }
            }
            .map { trx in
                RendableListPendingTransactionItem(trx: trx) { [weak action] in
                    action?.send(.openPendingTransaction(trx))
                }
            }
    }
}
