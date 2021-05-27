//
//  PendingTransactionsManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/05/2021.
//

import Foundation
import RxSwift

protocol TransactionsManagerType {
    var pendingTransactions: [PendingTransaction] {get}
    var transactionDidConfirm: PublishSubject<PendingTransaction> {get}
    func processPendingTransaction(_ transaction: PendingTransaction)
}

class PendingTransactionsManager: TransactionsManagerType {
    // MARK: - Constants
    private let bag = DisposeBag()
    
    // MARK: - Properties
    private let handler: TransactionHandler
    
    private(set) var pendingTransactions = [PendingTransaction]()
    let transactionDidConfirm = PublishSubject<PendingTransaction>()
    
    // MARK: - Initializer
    init(handler: TransactionHandler) {
        self.handler = handler
    }
    
    // MARK: - Methods
    func processPendingTransaction(_ transaction: PendingTransaction) {
        guard !pendingTransactions.contains(transaction) else {return}
        pendingTransactions.append(transaction)
        handler.observeTransactionCompletion(signature: transaction.signature)
            .subscribe(onCompleted: { [weak self] in
                self?.pendingTransactions.removeAll(where: {$0 == transaction})
                self?.transactionDidConfirm.onNext(transaction)
            }, onError: { [weak self] _ in
                self?.pendingTransactions.removeAll(where: {$0 == transaction})
            })
            .disposed(by: bag)
    }
}
