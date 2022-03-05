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
    var processingTransaction: ProcessingTransactionType {get}
    
    func getTransactionDescription(withAmount: Bool) -> String
    
    func sendAndObserveTransaction()
    func makeAnotherTransactionOrRetry()
    func navigate(to scene: PT.NavigatableScene)
}

extension PT {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        @Injected private var transactionHandler: TransactionHandlerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let processingTransaction: ProcessingTransactionType
        
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
        case let transaction as PT.OrcaSwapTransaction:
            return transaction.amount.toString(maximumFractionDigits: 9) + " " + transaction.sourceWallet.token.symbol +
                " → " +
                transaction.estimatedAmount.toString(maximumFractionDigits: 9) + " " + transaction.destinationWallet.token.symbol
        default:
            fatalError()
        }
    }
    
    // MARK: - Actions
    func sendAndObserveTransaction() {
        let index = transactionHandler.sendTransaction(processingTransaction)
        
        let unknownErrorInfo = PT.TransactionInfo(transactionId: nil, status: .error(SolanaSDK.Error.unknown))
        
        transactionHandler.observeTransaction(transactionIndex: index)
            .map {$0 ?? unknownErrorInfo}
            .catchAndReturn(unknownErrorInfo)
            .bind(to: transactionInfoSubject)
            .disposed(by: disposeBag)
    }
    
    func makeAnotherTransactionOrRetry() {
        if transactionInfoSubject.value.status.error == nil {
            // TODO: - Make another transaction
        } else {
            sendAndObserveTransaction()
        }
    }
    
    func navigate(to scene: PT.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
