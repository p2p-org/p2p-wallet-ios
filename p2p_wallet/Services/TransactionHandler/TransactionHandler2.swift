//
//  TransactionHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2022.
//

import Foundation
import RxSwift
import RxCocoa

protocol TransactionHandlerType {
    typealias TransactionIndex = Int
    func sendTransaction(_ processingTransaction: ProcessingTransactionType) -> TransactionIndex
    func observeTransaction(transactionIndex: TransactionIndex) -> Observable<PT.TransactionInfo?>
}

class TransactionHandler2: TransactionHandlerType {
    @Injected private var apiClient: ProcessTransactionAPIClient
    
    private let locker = NSLock()
    private let disposeBag = DisposeBag()
    private let transactionsSubject = BehaviorRelay<[PT.TransactionInfo]>(value: [])
    
    func sendTransaction(_ processingTransaction: ProcessingTransactionType) -> TransactionIndex
    {
        // get index to return
        let txIndex = transactionsSubject.value.count
        
        // add to processing
        var value = transactionsSubject.value
        value.append(
            .init(transactionId: nil, status: .sending)
        )
        transactionsSubject.accept(value)
        
        // process
        sendAndObserve(index: txIndex, processingTransaction: processingTransaction)
        
        return txIndex
    }
    
    func observeTransaction(transactionIndex: TransactionIndex) -> Observable<PT.TransactionInfo?>
    {
        transactionsSubject.map {$0[safe: transactionIndex]}
    }
    
    // MARK: - Helpers
    private func sendAndObserve(
        index: TransactionIndex,
        processingTransaction: ProcessingTransactionType
    ) {
        processingTransaction.createRequest()
            .subscribe(onSuccess: { [weak self] transactionID in
                guard let self = self else {return}
                
                self.updateTransactionAtIndex(index) { _ in
                    .init(
                        transactionId: transactionID,
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
    
    private func observe(index: TransactionIndex, transactionId: String) {
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
        
        apiClient.getSignatureStatus(signature: transactionId, configs: nil)
            .subscribe(on: scheduler)
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { [weak self] status in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                let txStatus: PT.TransactionInfo.TransactionStatus
                
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
                throw PT.Error.notEnoughNumberOfConfirmations
            }
            .retry(maxAttempts: .max, delayInSeconds: 1)
            .timeout(.seconds(60), scheduler: scheduler)
            .subscribe()
            .disposed(by: disposeBag)
            
    }
    
    @discardableResult
    private func updateTransactionAtIndex(
        _ index: TransactionIndex,
        update: (PT.TransactionInfo) -> PT.TransactionInfo
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
}
