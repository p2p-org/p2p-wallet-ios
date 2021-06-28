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
    private let transactionsSubject = BehaviorRelay<[ParsedTransaction]>(value: [])
    
    // MARK: - Initializer
    init(handler: TransactionHandler) {
        self.handler = handler
    }
    
    // MARK: - Methods
    func getProcessingTransactions() -> [ParsedTransaction] {
        transactionsSubject.value
    }
    
    func processingTransactionsObservable() -> Observable<[ParsedTransaction]> {
        transactionsSubject.asObservable()
    }
    
    func process(transaction: SolanaSDK.AnyTransaction) {
        var transactions = transactionsSubject.value
        transactions.append(
            .init(
                status: .processing(percent: 0),
                parsed: transaction
            )
        )
        transactionsSubject.accept(transactions)
        
        handler.observeTransactionCompletion(signature: transaction.signature ?? "")
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
            .catch {_ in .empty()}
            .subscribe(onCompleted: { [weak self] in
                guard let `self` = self else {return}
                var transactions = self.transactionsSubject.value
                if let index = transactions.firstIndex(where: {$0.parsed?.signature == transaction.signature})
                {
                    transactions[index].status = .confirmed
                }
                self.transactionsSubject.accept(transactions)
            })
            .disposed(by: disposeBag)
    }
}
