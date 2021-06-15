//
//  TransactionsManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/12/2020.
//

import Foundation
import RxSwift
import RxCocoa

class ProcessingTransactionsManager: ProcessingTransactionsRepository {
    // MARK: - Dependencies
    private let handler: TransactionHandler
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let transactionsSubject = BehaviorRelay<[ProcessingTransaction]>(value: [])
    
    // MARK: - Initializer
    init(handler: TransactionHandler) {
        self.handler = handler
    }
    
    // MARK: - Methods
    func getProcessingTransactions() -> [ProcessingTransaction] {
        transactionsSubject.value
    }
    
    func process(signature: String) -> Completable {
        var transactions = transactionsSubject.value
        transactions.append(
            .init(
                signature: signature,
                status: .processing(percent: 0)
            )
        )
        transactionsSubject.accept(transactions)
        
        return handler.observeTransactionCompletion(signature: signature)
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
            .catch {_ in .empty()}
            .do(onCompleted: { [weak self] in
                guard let `self` = self else {return}
                var transactions = self.transactionsSubject.value
                transactions.removeAll(where: {$0.signature == signature})
                self.transactionsSubject.accept(transactions)
            })
    }
}
