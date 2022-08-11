//
//  TransactionHandler+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Combine
import Foundation
import SolanaSwift

extension TransactionHandler {
    /// Send and observe transaction
    func sendAndObserve(
        index: TransactionIndex,
        processingTransaction: RawTransactionType
    ) async throws {
        do {
            let transactionID = try await processingTransaction.createRequest()
            // show notification
            //                self.notificationsService.showInAppNotification(.done(L10n.transactionHasBeenSent))

            // update status
            updateTransactionAtIndex(index) { _ in
                .init(
                    transactionId: transactionID,
                    sentAt: Date(),
                    rawTransaction: processingTransaction,
                    status: .sending
                )
            }

            // observe confirmations
            try? await observe(index: index, transactionId: transactionID)
        } catch {
            // update status
            notificationsService.showInAppNotification(.error(error))

            // mark transaction as failured
            updateTransactionAtIndex(index) { currentValue in
                var info = currentValue
                info.status = .error(error.readableDescription)
                return info
            }
        }
    }

    // MARK: - Helpers

    /// Observe confirmation statuses of given transaction
    private func observe(index: TransactionIndex, transactionId: String) async throws {
        for await status in apiClient.observeSignatureStatus(signature: transactionId) {
            updateTransactionAtIndex(index) { currentValue in
                var value = currentValue
                value.status = status
                if let slot = status.slot {
                    value.slot = slot
                }
                return value
            }
        }

        // update one last time
        updateTransactionAtIndex(index) { currentValue in
            var value = currentValue
            value.status = .finalized
            return value
        }
    }

    /// Update transaction
    @discardableResult
    private func updateTransactionAtIndex(
        _ index: TransactionIndex,
        update: (PendingTransaction) -> PendingTransaction
    ) -> Bool {
        var value = transactions

        if let currentValue = value[safe: index] {
            var newValue = update(currentValue)
            let numberOfConfirmations = newValue.status.numberOfConfirmations

            // write to repository if the transaction is not yet written and there is at least 1 confirmation
            if !newValue.writtenToRepository,
               numberOfConfirmations > 0
            {
                // manually update balances if socket is not connected
                updateRepository(with: newValue.rawTransaction)

                // mark as written
                newValue.writtenToRepository = true
            }

            // update
            value[index] = newValue
            transactions = value
            return true
        }

        return false
    }

    private func updateRepository(with rawTransaction: RawTransactionType) {
        switch rawTransaction {
        case let transaction as ProcessTransaction.SendTransaction:
            guard !socket.isConnected else { return }

            walletsRepository.batchUpdate { currentValue in
                var wallets = currentValue

                // update sender
                if let index = wallets.firstIndex(where: { $0.pubkey == transaction.sender.pubkey }) {
                    wallets[index].decreaseBalance(diffInLamports: transaction.amount)
                }

                // update receiver if user send to different wallet of THIS account
                if let index = wallets.firstIndex(where: { $0.pubkey == transaction.receiver.address }) {
                    wallets[index].increaseBalance(diffInLamports: transaction.amount)
                }

                // update paying wallet
                if let index = wallets.firstIndex(where: { $0.pubkey == transaction.payingFeeWallet?.pubkey }),
                   let feeInToken = transaction.feeInToken
                {
                    wallets[index].decreaseBalance(diffInLamports: feeInToken.total)
                }

                return wallets
            }
        case let transaction as ProcessTransaction.CloseTransaction:
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

        case let transaction as ProcessTransaction.SwapTransaction:
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
