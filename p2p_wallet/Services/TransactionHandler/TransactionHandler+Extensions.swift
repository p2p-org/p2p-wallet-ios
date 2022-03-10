//
//  TransactionHandler+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import RxSwift

extension TransactionHandler {
    /// Send and observe transaction
    func sendAndObserve(
        index: TransactionIndex,
        processingTransaction: RawTransactionType
    ) {
        processingTransaction.createRequest()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] transactionID in
                guard let self = self else {return}
                
                // show notification
                self.notificationsService.showInAppNotification(.done(L10n.transactionHasBeenSent))
                
                // update status
                self.updateTransactionAtIndex(index) { _ in
                    .init(
                        transactionId: transactionID,
                        sentAt: Date(),
                        rawTransaction: processingTransaction,
                        status: .confirmed(0)
                    )
                }
                
                // observe confirmations
                self.observe(index: index, transactionId: transactionID)
            }, onFailure: { [weak self] error in
                guard let self = self else {return}
                
                // update status
                self.notificationsService.showInAppNotification(.error(error))
                
                // mark transaction as failured
                self.updateTransactionAtIndex(index) { currentValue in
                    var info = currentValue
                    info.status = .error(error)
                    return info
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    /// Observe confirmation statuses of given transaction
    private func observe(index: TransactionIndex, transactionId: String) {
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
        
        apiClient.getSignatureStatus(signature: transactionId, configs: nil)
            .subscribe(on: scheduler)
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { [weak self] status in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                let txStatus: PendingTransaction.TransactionStatus
                
                if status.confirmations == nil || status.confirmationStatus == "finalized" {
                    txStatus = .finalized
                } else {
                    txStatus = .confirmed(Int(status.confirmations ?? 0))
                }
                
                self.updateTransactionAtIndex(index) { currentValue in
                    var value = currentValue
                    value.status = txStatus
                    value.slot = status.slot
                    return value
                }
            })
            .observe(on: scheduler)
            .map {$0.confirmations == nil || $0.confirmationStatus == "finalized"}
            .flatMapCompletable { confirmed in
                if confirmed {return .empty()}
                throw ProcessTransaction.Error.notEnoughNumberOfConfirmations
            }
            .retry(maxAttempts: .max, delayInSeconds: 1)
            .timeout(.seconds(60), scheduler: scheduler)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.notificationsService.showInAppNotification(.done(L10n.transactionHasBeenConfirmed))
            }, onError: { [weak self] error in
                debugPrint(error)
                self?.updateTransactionAtIndex(index) { currentValue in
                    var value = currentValue
                    value.status = .finalized
                    return value
                }
            })
            .disposed(by: disposeBag)
    }
    
    /// Update transaction
    @discardableResult
    private func updateTransactionAtIndex(
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
            transactionsSubject.accept(value)
            return true
        }
        
        return false
    }
    
    private func updateRepository(with rawTransaction: RawTransactionType) {
        switch rawTransaction {
        case let transaction as ProcessTransaction.SendTransaction:
            guard !socket.isConnected else {return}
            
            walletsRepository.batchUpdate { currentValue in
                var wallets = currentValue
                
                // update sender
                if let index = wallets.firstIndex(where: {$0.pubkey == transaction.sender.pubkey}) {
                    wallets[index].decreaseBalance(diffInLamports: transaction.amount)
                }
                
                // update receiver if user send to different wallet of THIS account
                if let index = wallets.firstIndex(where: {$0.pubkey == transaction.receiver.address}) {
                    wallets[index].increaseBalance(diffInLamports: transaction.amount)
                }
                
                // update paying wallet
                if let index = wallets.firstIndex(where: {$0.pubkey == transaction.payingFeeWallet?.pubkey}),
                   let feeInToken = transaction.feeInToken
                {
                    wallets[index].decreaseBalance(diffInLamports: feeInToken)
                }
                
                return wallets
            }
        case let transaction as ProcessTransaction.CloseTransaction:
            guard !socket.isConnected else {return}
            
            walletsRepository.batchUpdate { currentValue in
                var wallets = currentValue
                var reimbursedAmount = transaction.reimbursedAmount
                
                // remove closed wallet
                let wallet = transaction.closingWallet
                wallets.removeAll(where: {$0.pubkey == wallet.pubkey})
                
                // if closing non-native Solana wallet, then convert its balances and send it to native Solana wallet
                if wallet.token.symbol == "SOL" && !wallet.token.isNative {
                    reimbursedAmount += (wallet.lamports ?? 0)
                }
                
                // update native wallet
                if let index = wallets.firstIndex(where: {$0.isNativeSOL}) {
                    wallets[index].increaseBalance(diffInLamports: reimbursedAmount)
                }
                
                return wallets
            }
            
        case let transaction as ProcessTransaction.OrcaSwapTransaction:
            walletsRepository.batchUpdate { currentValue in
                var wallets = currentValue
                
                // update source wallet if socket is not connected
                if !socket.isConnected,
                    let index = wallets.firstIndex(where: {$0.pubkey == transaction.sourceWallet.pubkey})
                {
                    wallets[index].decreaseBalance(diffInLamports: transaction.amount.toLamport(decimals: transaction.sourceWallet.token.decimals))
                }
                
                // update destination wallet if exists
                if let index = wallets.firstIndex(where: {$0.pubkey == transaction.destinationWallet.pubkey}) {
                    // update only if socket is not connected
                    if !socket.isConnected {
                        wallets[index].increaseBalance(diffInLamports: transaction.estimatedAmount.toLamport(decimals: transaction.destinationWallet.token.decimals))
                    }
                }
                
                // add destination wallet if not exists, event when socket is connected, because socket doesn't handle new wallet
                else if let publicKey = try? SolanaSDK.PublicKey.associatedTokenAddress(
                    walletAddress: try SolanaSDK.PublicKey(string: transaction.authority),
                    tokenMintAddress: try SolanaSDK.PublicKey(string: transaction.destinationWallet.mintAddress)
                ) {
                    var destinationWallet = transaction.destinationWallet
                    destinationWallet.pubkey = publicKey.base58EncodedString
                    destinationWallet.lamports = transaction.estimatedAmount.toLamport(decimals: destinationWallet.token.decimals)
                    wallets.append(destinationWallet)
                }
                
                // update paying wallet
                if !socket.isConnected {
                    for fee in transaction.fees {
                        switch fee.type {
                        case .liquidityProviderFee:
                            break
                        case .accountCreationFee:
                            if let index = wallets.firstIndex(where: {$0.mintAddress == fee.token.address}) {
                                wallets[index].decreaseBalance(diffInLamports: fee.lamports)
                            }
                        case .orderCreationFee:
                            break
                        case .transactionFee:
                            if let index = wallets.firstIndex(where: {$0.mintAddress == fee.token.address}) {
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
