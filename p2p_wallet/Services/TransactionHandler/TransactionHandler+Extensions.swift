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
    ) async throws {
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
    }

    // MARK: - Helpers

    /// Observe confirmation statuses of given transaction
    private func observe(index: TransactionIndex, transactionId: String) {
        Task { [weak self] in
            guard let self else { return }
            // for debuging
            if transactionId.hasPrefix(.fakeTransactionSignaturePrefix) {
                // mark as confirmed
                await self.updateTransactionAtIndex(index) { currentValue in
                    var value = currentValue
                    value.status = .confirmed(3)
                    return value
                }
                
                // wait for 2 secs
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                // mark as finalized
                await MainActor.run { [weak self] in
                    self?.notificationsService.showInAppNotification(.done(L10n.transactionHasBeenConfirmed))
                }
                await self.updateTransactionAtIndex(index) { currentValue in
                    var value = currentValue
                    value.status = .finalized
                    return value
                }
                return
            }
            
            // for production
            var statuses: [TransactionStatus] = []
            for try await status in self.apiClient.observeSignatureStatus(signature: transactionId) {
                statuses.append(status)
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
            
            // TODO: - Transaction was sent successfuly but we could not retrieve the status.
            // Mark as finalized anyway or throw an error?
            if statuses.isEmpty {
                await MainActor.run { [weak self] in
                    self?.notificationsService.showInAppNotification(.done(L10n.transactionHasBeenConfirmed))
                }
                await self.updateTransactionAtIndex(index) { currentValue in
                    var value = currentValue
                    value.status = .finalized
                    return value
                }
            }
        }
    }

    /// Update transaction
    @MainActor @discardableResult func updateTransactionAtIndex(
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

// MARK: - Helpers

extension SolanaSwift.APIClientError: CustomNSError {
    public var errorUserInfo: [String : Any] {
        func getDebugDescription() -> String {
            switch self {
            case .cantEncodeParams:
                return "Can not decode params"
            case .invalidAPIURL:
                return "Invalid APIURL"
            case .invalidResponse:
                return "Invalid response"
            case .responseError(let response):
                return response.message ?? "\(response)"
            }
        }
        
        return [NSDebugDescriptionErrorKey: getDebugDescription()]
    }
}
