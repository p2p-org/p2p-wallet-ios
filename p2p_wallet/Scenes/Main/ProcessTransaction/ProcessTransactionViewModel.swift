//
//  ProcessTransactionViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2021.
//

import UIKit
import RxSwift
import RxCocoa
import Action

enum ProcessTransactionNavigatableScene {
    case viewInExplorer(signature: String)
    case done
    case cancel
}

struct TransactionHandler {
    var transaction: Transaction?
    var error: Error?
}

class ProcessTransactionViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let transactionsManager: TransactionsManager
    var tryAgainAction: CocoaAction?
    
    var transaction: Transaction? {transactionHandler.value.transaction}
    var error: Error? {transactionHandler.value.error}
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ProcessTransactionNavigatableScene>()
    
    let transactionHandler = BehaviorRelay<TransactionHandler>(value: TransactionHandler())
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(transactionsManager: TransactionsManager) {
        self.transactionsManager = transactionsManager
        bind()
    }
    
    func bind() {
        transactionsManager.transactions
            .map {$0.first(where: {$0.signature == self.transaction?.signature})}
            .filter {$0 != nil}
            .subscribe(onNext: {[unowned self] transaction in
                if var transaction = self.transaction {
                    transaction.status = .confirmed
                    self.transactionHandler.accept(TransactionHandler(transaction: transaction, error: self.error))
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func tryAgain() {
        tryAgainAction?.execute()
    }
    
    @objc func viewInExplorer() {
        guard let signature = transactionHandler.value.transaction?.signature else {return}
        navigationSubject.onNext(.viewInExplorer(signature: signature))
    }
    
    @objc func done() {
        navigationSubject.onNext(.done)
    }
    
    @objc func cancel() {
        navigationSubject.onNext(.cancel)
    }
}
