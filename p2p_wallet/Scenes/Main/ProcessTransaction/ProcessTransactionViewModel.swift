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

struct TransactionInfo {
    var transaction: Transaction?
    var error: Error?
}

class ProcessTransactionViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let transactionsManager: TransactionsManager
    let pricesRepository: PricesRepository
    var tryAgainAction: CocoaAction?
    
    var transaction: Transaction? {transactionInfo.value.transaction}
    var error: Error? {transactionInfo.value.error}
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ProcessTransactionNavigatableScene>()
    
    let transactionInfo = BehaviorRelay<TransactionInfo>(value: TransactionInfo())
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(
        transactionsManager: TransactionsManager,
        pricesRepository: PricesRepository
    ) {
        self.transactionsManager = transactionsManager
        self.pricesRepository = pricesRepository
        bind()
    }
    
    func bind() {
        transactionsManager.transactions
            .map {$0.first(where: {$0.signature == self.transaction?.signature})}
            .filter {$0 != nil}
            .subscribe(onNext: {[unowned self] transaction in
                if var transaction = self.transaction {
                    transaction.status = .confirmed
                    self.transactionInfo.accept(TransactionInfo(transaction: transaction, error: self.error))
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func tryAgain() {
        tryAgainAction?.execute()
    }
    
    @objc func viewInExplorer() {
        guard let signature = transactionInfo.value.transaction?.signature else {return}
        navigationSubject.onNext(.viewInExplorer(signature: signature))
    }
    
    @objc func done() {
        navigationSubject.onNext(.done)
    }
    
    @objc func cancel() {
        navigationSubject.onNext(.cancel)
    }
}
