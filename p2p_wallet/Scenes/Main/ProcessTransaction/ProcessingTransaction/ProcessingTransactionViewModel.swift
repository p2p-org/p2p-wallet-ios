//
//  ProcessingTransactionViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/05/2021.
//

import Foundation
import RxSwift
import RxCocoa

enum ProcessingTransactionNavigatableScene {
    case viewInExplorer(signature: String)
    case done
}

protocol ProcessingTransactionTryAgainHandler {
    func tryAgain()
}

class ProcessingTransactionViewModel: ViewModelType {
    // MARK: - Nested type
    struct Input {
        
    }
    
    struct Output {
        let navigatingScene: Driver<ProcessingTransactionNavigatableScene>
    }
    
    // MARK: - Dependencies
    private let pendingTransaction: PendingTransaction
    private let transactionsManager: TransactionsManager
    private let pricesRepository: PricesRepository
    private let tryAgainHandler: ProcessingTransactionTryAgainHandler
    
    // MARK: - Constants
    private let disposeBag = DisposeBag()
    private let navigationSubject = PublishSubject<ProcessingTransactionNavigatableScene>()
    
    // MARK: - Properties
    let input: Input
    let output: Output
    
    // MARK: - Initializers
    init(
        pendingTransaction: PendingTransaction,
        transactionsManager: TransactionsManager,
        pricesRepository: PricesRepository,
        tryAgainHandler: ProcessingTransactionTryAgainHandler
    ) {
        self.pendingTransaction = pendingTransaction
        self.transactionsManager = transactionsManager
        self.pricesRepository = pricesRepository
        self.tryAgainHandler = tryAgainHandler
        
        self.input = Input()
        self.output = Output(navigatingScene: navigationSubject.asDriver(onErrorJustReturn: .done))
    }
    
    // MARK: - Methods
    @objc func tryAgain() {
        tryAgainHandler.tryAgain()
    }
    
    @objc func viewInExplorer() {
        navigationSubject.onNext(.viewInExplorer(signature: signature))
    }
}
