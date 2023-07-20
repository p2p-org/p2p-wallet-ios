import Foundation
import Combine

enum HistoryViewModelAggregator {

    
    /// Aggregate pending transactions.
    /// - Parameters:
    ///   - pendingTransactionService: Pending transaction service.
    ///   - actionSubject: Action subject for transaction.
    ///   - mint: Filter transaction by token mint address.
    /// - Returns: Rendable pending transaction.
    static func pendingTransaction(
        pendingTransactionService: TransactionHandlerType,
        actionSubject: PassthroughSubject<NewHistoryAction, Never>,
        mint: String? = nil // mint == nil mean all transaction
    ) -> AnyPublisher<[RendableListPendingTransactionItem], Never> {
        pendingTransactionService.observePendingTransactions()
            .map { transactions in
                transactions
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
                    .map { [weak actionSubject] trx in
                        RendableListPendingTransactionItem(trx: trx) {
                            actionSubject?.send(.openPendingTransaction(trx))
                        }
                    }
            }
            .eraseToAnyPublisher()
    }

    
}
