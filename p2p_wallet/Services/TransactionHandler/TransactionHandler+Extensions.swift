//
//  TransactionHandler+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import Sentry
import SolanaSwift

extension TransactionHandler {
    /// Send and observe transaction
    func sendAndObserve(
        index: TransactionIndex,
        processingTransaction: RawTransactionType
    ) {
        Task {
            do {
                let transactionID = try await processingTransaction.createRequest()
                // update status
                _ = await updateTransactionAtIndex(index) { _ in
                    .init(
                        trxIndex: index,
                        transactionId: transactionID,
                        sentAt: Date(),
                        rawTransaction: processingTransaction,
                        status: .confirmed(0)
                    )
                }

                // Observe confirmations
                observe(index: index, transactionId: transactionID)
            } catch {
                // Update status
                if (error as NSError).isNetworkConnectionError {
                    self.notificationsService.showConnectionErrorNotification()
                } else {
                    self.notificationsService.showDefaultErrorNotification()
                }

                // Report error
                errorObserver.handleError(error)

                // mark transaction as failured
                _ = await updateTransactionAtIndex(index) { currentValue in
                    var info = currentValue
                    info.status = .error(error)
                    return info
                }
            }
        }
    }

    // MARK: - Helpers

    /// Observe confirmation statuses of given transaction
    private func observe(index: TransactionIndex, transactionId: String) {
        Task { [weak self] in
            guard let self else { return }
            for try await status in self.apiClient.observeSignatureStatus(signature: transactionId) {
                let txStatus: PendingTransaction.TransactionStatus
                var slot: UInt64?
                switch status {
                case .sending:
                    continue
                case .confirmed(let numberOfConfirmations, let sl):
                    slot = sl
                    txStatus = .confirmed(Int(numberOfConfirmations))
                case .finalized:
                    txStatus = .finalized
                case .error(let error):
                    print(error ?? "")
                    txStatus = .error(SolanaError.other(error ?? ""))
                }

                _ = await self.updateTransactionAtIndex(index) { currentValue in
                    var value = currentValue
                    value.status = txStatus
                    if let slot {
                        value.slot = slot
                    }
                    return value
                }
            }
        }
    }

    /// Update transaction
    @MainActor @discardableResult private func updateTransactionAtIndex(
        _ index: TransactionIndex,
        update: (PendingTransaction) -> PendingTransaction
    ) -> Bool {
        var value = transactionsSubject.value

        if let currentValue = value[safe: index] {
            var newValue = update(currentValue)

           // update
            value[index] = newValue
            transactionsSubject.send(value)
            return true
        }

        return false
    }
}
