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
}

struct TransactionHandler {
    var transaction: Transaction?
    var error: Error?
}

class ProcessTransactionViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    var tryAgainAction: CocoaAction?
    
    var transaction: Transaction? {transactionHandler.value.transaction}
    var error: Error? {transactionHandler.value.error}
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ProcessTransactionNavigatableScene>()
    
    let transactionHandler = BehaviorRelay<TransactionHandler>(value: TransactionHandler())
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Actions
    @objc func tryAgain() {
        tryAgainAction?.execute()
    }
    
    @objc func viewInExplorer() {
        guard let signature = transactionHandler.value.transaction?.signature else {return}
        navigationSubject.onNext(.viewInExplorer(signature: signature))
    }
    
    @objc func close() {
        navigationSubject.onNext(.done)
    }
}
