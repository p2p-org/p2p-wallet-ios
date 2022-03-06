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
    var navigationDriver: Driver<ProcessTransaction.NavigatableScene?> {get}
    var transactionInfoDriver: Driver<PendingTransaction> {get}
    var isSwapping: Bool {get}
    var transactionID: String? {get}
    var processingTransaction: ProcessingTransactionType {get}
    
    func getMainDescription() -> String
    
    func sendAndObserveTransaction()
    func makeAnotherTransactionOrRetry()
    func navigate(to scene: ProcessTransaction.NavigatableScene)
}

extension ProcessTransaction {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var transactionHandler: TransactionHandlerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let processingTransaction: ProcessingTransactionType
        
        // MARK: - Subjects
        private let transactionInfoSubject: BehaviorRelay<PendingTransaction>
        
        // MARK: - Initializer
        init(processingTransaction: ProcessingTransactionType) {
            self.processingTransaction = processingTransaction
            self.transactionInfoSubject = BehaviorRelay<PendingTransaction>(value: .init(transactionId: nil, sentAt: Date(), rawTransaction: processingTransaction, status: .sending))
        }
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension ProcessTransaction.ViewModel: PTViewModelType {
    var navigationDriver: Driver<ProcessTransaction.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var transactionInfoDriver: Driver<PendingTransaction> {
        transactionInfoSubject.asDriver()
    }
    
    var isSwapping: Bool {
        processingTransaction.isSwap
    }
    
    var transactionID: String? {
        transactionInfoSubject.value.transactionId
    }
    
    func getMainDescription() -> String {
        processingTransaction.mainDescription
    }
    
    // MARK: - Actions
    func sendAndObserveTransaction() {
        let index = transactionHandler.sendTransaction(processingTransaction)
        
        let unknownErrorInfo = PendingTransaction(transactionId: nil, sentAt: Date(), rawTransaction: processingTransaction, status: .error(SolanaSDK.Error.unknown))
        
        transactionHandler.observeTransaction(transactionIndex: index)
            .map {$0 ?? unknownErrorInfo}
            .catchAndReturn(unknownErrorInfo)
            .bind(to: transactionInfoSubject)
            .disposed(by: disposeBag)
    }
    
    func makeAnotherTransactionOrRetry() {
        if transactionInfoSubject.value.status.error == nil {
            // log
            let status = transactionInfoSubject.value.status.rawValue
            switch processingTransaction {
            case is ProcessTransaction.SendTransaction:
                analyticsManager.log(event: .sendMakeAnotherTransactionClick(txStatus: status))
            case is ProcessTransaction.SwapTransaction:
                analyticsManager.log(event: .swapMakeAnotherTransactionClick(txStatus: status))
            default:
                break
            }
            
            // TODO: - Make another transaction
            
        } else {
            // log
            if let error = transactionInfoSubject.value.status.error?.readableDescription {
                switch processingTransaction {
                case is ProcessTransaction.SendTransaction:
                    analyticsManager.log(event: .sendTryAgainClick(error: error))
                case is ProcessTransaction.SwapTransaction:
                    analyticsManager.log(event: .swapTryAgainClick(error: error))
                default:
                    break
                }
            }
            
            sendAndObserveTransaction()
        }
    }
    
    func navigate(to scene: ProcessTransaction.NavigatableScene) {
        // log
        let status = transactionInfoSubject.value.status.rawValue
        switch scene {
        case .detail:
            break
        case .explorer:
            switch processingTransaction {
            case is ProcessTransaction.SendTransaction:
                analyticsManager.log(event: .sendExplorerClick(txStatus: status))
            case is ProcessTransaction.SwapTransaction:
                analyticsManager.log(event: .swapExplorerClick(txStatus: status))
            default:
                break
            }
        }
        
        // navigate
        navigationSubject.accept(scene)
    }
}
