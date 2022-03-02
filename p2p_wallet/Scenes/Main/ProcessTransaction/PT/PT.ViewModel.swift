//
//  PT.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import RxSwift
import RxCocoa
import Resolver

protocol PTViewModelType {
    var navigationDriver: Driver<PT.NavigatableScene?> {get}
    var transactionInfoDriver: Driver<PT.TransactionInfo> {get}
    var isSwapping: Bool {get}
    var transactionID: String? {get}
    
    func getTransactionDescription(withAmount: Bool) -> String
    
    func sendAndObserveTransaction()
    func navigate(to scene: PT.NavigatableScene)
}

extension PT {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        @Injected private var apiClient: ProcessTransactionAPIClient
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private let processingTransaction: ProcessingTransactionType
        
        // MARK: - Subjects
        private let transactionInfoSubject = BehaviorRelay<TransactionInfo>(value: .init(transactionId: nil, status: .sending))
        
        // MARK: - Initializer
        init(processingTransaction: ProcessingTransactionType) {
            self.processingTransaction = processingTransaction
        }
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension PT.ViewModel: PTViewModelType {
    var navigationDriver: Driver<PT.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var transactionInfoDriver: Driver<PT.TransactionInfo> {
        transactionInfoSubject.asDriver()
    }
    
    var isSwapping: Bool {
        processingTransaction.isSwap
    }
    
    var transactionID: String? {
        transactionInfoSubject.value.transactionId
    }
    
    func getTransactionDescription(withAmount: Bool) -> String {
        switch processingTransaction {
        case let transaction as PT.SendTransaction:
            var desc = transaction.sender.token.symbol + " → " + (transaction.receiver.name ?? transaction.receiver.address.truncatingMiddle(numOfSymbolsRevealed: 4))
            if withAmount {
                let amount = transaction.amount.convertToBalance(decimals: transaction.sender.token.decimals)
                    .toString(maximumFractionDigits: 9)
                desc = amount + " " + desc
            }
            return desc
        default:
            return ""
        }
    }
    
    // MARK: - Actions
    func sendAndObserveTransaction() {
        // create request
        processingTransaction.createRequest()
            .subscribe(onSuccess: { [weak self] transactionID in
                guard let self = self else {return}
                self.observe(transactionId: transactionID)
            }, onFailure: { [weak self] error in
                guard let self = self else {return}
                self.transactionInfoSubject.accept(self.updateTransactionInfo(status: .error(error)))
            })
            .disposed(by: disposeBag)
    }
    
    func navigate(to scene: PT.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    // MARK: - Helpers
    private func observe(transactionId: String) {
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
        
        apiClient.getSignatureStatus(signature: transactionId, configs: nil)
            .subscribe(on: scheduler)
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { [weak self] status in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                let transactionInfo: PT.TransactionInfo
                if status.confirmations == nil || status.confirmationStatus == "finalized" {
                    transactionInfo = self.updateTransactionInfo(status: .finalized)
                } else {
                    transactionInfo = self.updateTransactionInfo(status: .confirmed(Int(status.confirmations ?? 0)))
                }
                
                self.transactionInfoSubject.accept(transactionInfo)
            })
            .observe(on: scheduler)
            .map {$0.confirmations == nil || $0.confirmationStatus == "finalized"}
            .flatMapCompletable { confirmed in
                if confirmed {return .empty()}
                throw PT.Error.notEnoughNumberOfConfirmations
            }
            .retry(maxAttempts: .max, delayInSeconds: 1)
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
            .subscribe()
            .disposed(by: disposeBag)
            
    }
    
    private func updateTransactionInfo(status: PT.TransactionInfo.TransactionStatus) -> PT.TransactionInfo {
        var info = transactionInfoSubject.value
        info.status = status
        return info
    }
}
