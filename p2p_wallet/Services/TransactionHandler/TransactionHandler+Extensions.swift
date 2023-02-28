//
//  TransactionHandler+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import SolanaSwift
import Sentry

extension TransactionHandler {
    /// Send and observe transaction
    func sendAndObserve(
        index: TransactionIndex,
        processingTransaction: RawTransactionType
    ) {
        Task {
            do {
                let transactionID = try await processingTransaction.createRequest()
                // show notification
//                self.notificationsService.showInAppNotification(.done(L10n.transactionHasBeenSent))

                // update status
                await updateTransactionAtIndex(index) { _ in
                    .init(
                        trxIndex: index,
                        transactionId: transactionID,
                        sentAt: Date(),
                        rawTransaction: processingTransaction,
                        status: .confirmed(0)
                    )
                }
                

                // observe confirmations
                observe(index: index, transactionId: transactionID)
            } catch {
                // update status
                if (error as NSError).isNetworkConnectionError {
                    self.notificationsService.showConnectionErrorNotification()
                } else {
                    self.notificationsService.showDefaultErrorNotification()
                }
                SentrySDK.capture(error: error)

                // mark transaction as failured
                await updateTransactionAtIndex(index) { currentValue in
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
                    await MainActor.run { [weak self] in
                        self?.notificationsService.showInAppNotification(.done(L10n.transactionHasBeenConfirmed))
                    }
                case .error(let error):
                    print(error ?? "")
                    txStatus = .error(SolanaError.other(error ?? ""))
                }
                
                await self.updateTransactionAtIndex(index) { currentValue in
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

            // write to repository if the transaction is not yet written and there is at least 1 confirmation
            if !newValue.writtenToRepository,
               let numberOfConfirmations = newValue.status.numberOfConfirmations,
               numberOfConfirmations > 0
            {
                // manually update balances if socket is not connected
                updateRepository(with: newValue.rawTransaction)

                // mark as written
                newValue.writtenToRepository = true
            }

            // update
            value[index] = newValue
            transactionsSubject.send(value)
            return true
        }

        return false
    }

    @MainActor private func updateRepository(with rawTransaction: RawTransactionType) {
        switch rawTransaction {
        case let transaction as SendTransaction:
            guard !socket.isConnected else { return }

            walletsRepository.batchUpdate { currentValue in
                var wallets = currentValue

                // update sender
                if let index = wallets.firstIndex(where: { $0.pubkey == transaction.walletToken.pubkey }) {
                    wallets[index].decreaseBalance(diffInLamports: transaction.amount.toLamport(decimals: transaction.walletToken.token.decimals))
                }

                // update receiver if user send to different wallet of THIS account
                if let index = wallets.firstIndex(where: { $0.pubkey == transaction.recipient.address }) {
                    wallets[index].increaseBalance(diffInLamports: transaction.amount.toLamport(decimals: wallets[index].token.decimals))
                }

                // update paying wallet
                if let index = wallets.firstIndex(where: { $0.pubkey == transaction.payingFeeWallet?.pubkey }) {
                    let feeInToken = transaction.feeInToken
                    wallets[index].decreaseBalance(diffInLamports: feeInToken.total)
                }

                return wallets
            }
        case let transaction as CloseTransaction:
            guard !socket.isConnected else { return }

            walletsRepository.batchUpdate { currentValue in
                var wallets = currentValue
                var reimbursedAmount = transaction.reimbursedAmount

                // remove closed wallet
                let wallet = transaction.closingWallet
                wallets.removeAll(where: { $0.pubkey == wallet.pubkey })

                // if closing non-native Solana wallet, then convert its balances and send it to native Solana wallet
                if wallet.token.symbol == "SOL", !wallet.token.isNative {
                    reimbursedAmount += (wallet.lamports ?? 0)
                }

                // update native wallet
                if let index = wallets.firstIndex(where: { $0.isNativeSOL }) {
                    wallets[index].increaseBalance(diffInLamports: reimbursedAmount)
                }

                return wallets
            }

        case let transaction as SwapTransaction:
            walletsRepository.batchUpdate { currentValue in
                var wallets = currentValue

                // update source wallet if socket is not connected
                if !socket.isConnected,
                   let index = wallets.firstIndex(where: { $0.pubkey == transaction.sourceWallet.pubkey })
                {
                    wallets[index]
                        .decreaseBalance(diffInLamports: transaction.amount
                            .toLamport(decimals: transaction.sourceWallet.token.decimals))
                }

                // update destination wallet if exists
                if let index = wallets.firstIndex(where: { $0.pubkey == transaction.destinationWallet.pubkey }) {
                    // update only if socket is not connected
                    if !socket.isConnected {
                        wallets[index]
                            .increaseBalance(diffInLamports: transaction.estimatedAmount
                                .toLamport(decimals: transaction.destinationWallet.token.decimals))
                    }
                }

                // add destination wallet if not exists, event when socket is connected, because socket doesn't handle new wallet
                else if let publicKey = try? PublicKey.associatedTokenAddress(
                    walletAddress: try PublicKey(string: transaction.authority),
                    tokenMintAddress: try PublicKey(string: transaction.destinationWallet.mintAddress)
                ) {
                    var destinationWallet = transaction.destinationWallet
                    destinationWallet.pubkey = publicKey.base58EncodedString
                    destinationWallet.lamports = transaction.estimatedAmount
                        .toLamport(decimals: destinationWallet.token.decimals)
                    wallets.append(destinationWallet)
                }

                // update paying wallet
                if !socket.isConnected {
                    for fee in transaction.fees {
                        switch fee.type {
                        case .liquidityProviderFee:
                            break
                        case .accountCreationFee:
                            if let index = wallets.firstIndex(where: { $0.mintAddress == fee.token.address }) {
                                wallets[index].decreaseBalance(diffInLamports: fee.lamports)
                            }
                        case .orderCreationFee:
                            break
                        case .transactionFee:
                            if let index = wallets.firstIndex(where: { $0.mintAddress == fee.token.address }) {
                                wallets[index].decreaseBalance(diffInLamports: fee.lamports)
                            }
                        case .depositWillBeReturned:
                            break
                        }
                    }
                }

                return wallets
            }
        default:
            break
        }
    }
}
