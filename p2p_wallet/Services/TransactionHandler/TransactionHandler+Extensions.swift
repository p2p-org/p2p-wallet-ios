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
        processingTransaction: ProcessingTransactionType
    ) {
        processingTransaction.createRequest()
            .do(onSuccess: { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.notificationsService.showInAppNotification(.done(L10n.transactionHasBeenSent))
                }
            }, onError: { [weak self] error in
                DispatchQueue.main.async { [weak self] in
                    self?.notificationsService.showInAppNotification(.error(error))
                }
            })
        
            .subscribe(onSuccess: { [weak self] transactionID in
                guard let self = self else {return}
                
                self.updateTransactionAtIndex(index) { _ in
                    .init(
                        transactionId: transactionID,
                        sentAt: Date(),
                        rawTransaction: processingTransaction,
                        status: .confirmed(0)
                    )
                }
                
                self.observe(index: index, transactionId: transactionID)
            }, onFailure: { [weak self] error in
                guard let self = self else {return}
                self.updateTransactionAtIndex(index) { currentValue in
                    var info = currentValue
                    info.status = .error(error)
                    return info
                }
            })
            .disposed(by: disposeBag)
    }
    
    /// Update transaction
    @discardableResult
    func updateTransactionAtIndex(
        _ index: TransactionIndex,
        update: (PendingTransaction) -> PendingTransaction
    ) -> Bool {
        var value = transactionsSubject.value
        
        if let currentValue = value[safe: index] {
            let newValue = update(currentValue)
            value[index] = newValue
            locker.lock()
            transactionsSubject.accept(value)
            locker.unlock()
            return true
        }
        
        return false
    }
    
    // MARK: - Helpers
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
}
