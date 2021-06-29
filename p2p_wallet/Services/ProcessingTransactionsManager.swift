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
    private let transactionsSubject = BehaviorRelay<[SolanaSDK.ParsedTransaction]>(value: [])
    
    // MARK: - Initializer
    init(handler: TransactionHandler) {
        self.handler = handler
    }
    
    // MARK: - Methods
    func getProcessingTransactions() -> [SolanaSDK.ParsedTransaction] {
        transactionsSubject.value
    }
    
    func processingTransactionsObservable() -> Observable<[SolanaSDK.ParsedTransaction]> {
        transactionsSubject.asObservable()
    }
    
    func process(transaction: SolanaSDK.ParsedTransaction) {
        var transactions = transactionsSubject.value
        transactions.append(transaction)
        transactionsSubject.accept(transactions)
        
        handler.observeTransactionCompletion(signature: transaction.signature ?? "")
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
            .catch {_ in .empty()}
            .subscribe(onCompleted: { [weak self] in
                guard let `self` = self else {return}
                var transactions = self.transactionsSubject.value
                if let index = transactions.firstIndex(where: {$0.signature == transaction.signature})
                {
                    transactions[index].status = .confirmed
                }
                self.transactionsSubject.accept(transactions)
            })
            .disposed(by: disposeBag)
    }
}
