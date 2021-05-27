//
//  PendingTransactionsManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/05/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol TransactionsManagerType {
    var pendingTransactions: [PendingTransaction] {get}
    var pendingTransactionsObservable: Observable<[PendingTransaction]> {get}
    func processPendingTransaction(_ transaction: PendingTransaction)
}

class PendingTransactionsManager: TransactionsManagerType {
    // MARK: - Constants
    private let bag = DisposeBag()
    
    // MARK: - Properties
    private let handler: TransactionHandler
    
    private let pendingTransactionsRelay = BehaviorRelay<[PendingTransaction]>(value: [])
    
    var pendingTransactions: [PendingTransaction] {
        pendingTransactionsRelay.value
    }
    var pendingTransactionsObservable: Observable<[PendingTransaction]> {
        pendingTransactionsRelay.asObservable()
    }
    
    // MARK: - Initializer
    init(handler: TransactionHandler) {
        self.handler = handler
    }
    
    // MARK: - Methods
    func processPendingTransaction(_ transaction: PendingTransaction) {
        guard !pendingTransactions.contains(transaction) else {return}
        
        // modify transactions
        var transactions = pendingTransactions
        transactions.append(transaction)
        pendingTransactionsRelay.accept(transactions)
        
        // handle transaction
        handler.observeTransactionCompletion(signature: transaction.signature)
            .subscribe(onCompleted: { [weak self] in
                guard let strongSelf = self else {return}
                var transactions = strongSelf.pendingTransactions
                transactions.removeAll(where: {$0 == transaction})
                strongSelf.pendingTransactionsRelay.accept(transactions)
            }, onError: { [weak self] _ in
                guard let strongSelf = self else {return}
                var transactions = strongSelf.pendingTransactions
                transactions.removeAll(where: {$0 == transaction})
                strongSelf.pendingTransactionsRelay.accept(transactions)
            })
            .disposed(by: bag)
    }
}
