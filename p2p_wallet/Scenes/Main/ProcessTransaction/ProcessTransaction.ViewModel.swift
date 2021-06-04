//
//  ProcessTransaction.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension ProcessTransaction {
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {}
        struct Output {
            let navigationScene: Driver<NavigatableScene>
            let transactionId: Driver<SolanaSDK.TransactionID?>
            let transactionType: TransactionType
            let transactionStatus: Driver<TransactionStatus>
            let pricesRepository: PricesRepository
            var reimbursedAmount: Double?
        }
        
        // MARK: - Dependencies
        private let transactionType: TransactionType
        private let request: Single<SolanaSDK.TransactionID>
        private let transactionHandler: TransactionHandler
        private let transactionManager: TransactionsManager
        private let walletsRepository: WalletsRepository
        private let apiClient: ProcessTransactionAPIClient
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        let input: Input
        var output: Output
        
        // MARK: - Subject
        private let navigationSubject = PublishSubject<NavigatableScene>()
        private let transactionIdSubject = BehaviorRelay<SolanaSDK.TransactionID?>(value: nil)
        private let transactionStatusSubject = BehaviorRelay<TransactionStatus>(value: .processing)
        
        // MARK: - Initializer
        init(
            transactionType: TransactionType,
            request: Single<SolanaSDK.TransactionID>,
            transactionHandler: TransactionHandler,
            transactionManager: TransactionsManager,
            walletsRepository: WalletsRepository,
            pricesRepository: PricesRepository,
            apiClient: ProcessTransactionAPIClient
        ) {
            self.transactionType = transactionType
            self.request = request
            self.transactionHandler = transactionHandler
            self.transactionManager = transactionManager
            self.walletsRepository = walletsRepository
            self.apiClient = apiClient
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: .showExplorer(transactionID: "")),
                transactionId: transactionIdSubject
                    .asDriver(),
                transactionType: transactionType,
                transactionStatus: transactionStatusSubject
                    .asDriver(),
                pricesRepository: pricesRepository
            )
            
            executeRequest()
        }
        
        // MARK: - Actions
        func fetchReimbursedAmountForClosingTransaction() -> Single<Double> {
            apiClient.getReimbursedAmountForClosingToken()
                .catchAndReturn(0)
                .do(onSuccess: {[weak self] amount in
                    self?.output.reimbursedAmount = amount
                })
        }
        
        @objc func executeRequest() {
            switch transactionType {
            case .send(let fromWallet, let receiver, let amount):
                executeSend(fromWallet: fromWallet, receiver: receiver, amount: amount)
            case .swap(let from, let to, let inputAmount, let estimatedAmount):
                executeSwap(from: from, to: to, inputAmount: inputAmount, estimatedAmount: estimatedAmount)
            case .closeAccount(let wallet):
                executeCloseAccount(wallet)
            }
        }
        
        @objc func showExplorer() {
            guard let id = transactionIdSubject.value else {return}
            navigationSubject.onNext(.showExplorer(transactionID: id))
        }
        
        @objc func done() {
            navigationSubject.onNext(.done)
        }
        
        @objc func cancel() {
            navigationSubject.onNext(.cancel)
        }
        
        // MARK: - Helpers
        private func executeSend(
            fromWallet: Wallet,
            receiver: String,
            amount: Double
        ) {
            // Verify address
            guard NSRegularExpression.publicKey.matches(receiver) else {
                transactionStatusSubject
                    .accept(.error(SolanaSDK.Error.other(L10n.wrongWalletAddress)))
                return
            }
            
            // Execute request
            executeRequest { [weak self] transactionId in
                // update wallet
                self?.walletsRepository.updateWallet(where: {$0.pubkey == fromWallet.pubkey}, transform: {
                    var wallet = $0
                    let lamports = amount.toLamport(decimals: fromWallet.token.decimals)
                    wallet.lamports = (wallet.lamports ?? 0) - lamports
                    return wallet
                })
                
                // FIXME: - Remove transactionManager
                let transaction = Transaction(
                    signatureInfo: .init(signature: transactionId),
                    type: .send,
                    amount: -amount,
                    symbol: fromWallet.token.symbol,
                    status: .processing
                )
                self?.transactionManager.process(transaction)
            }
        }
        
        private func executeSwap(
            from: Wallet,
            to: Wallet,
            inputAmount: Double,
            estimatedAmount: Double
        ) {
            executeRequest { [weak self] transactionId in
                // update source wallet
                self?.walletsRepository.updateWallet(where: {$0.pubkey == from.pubkey}, transform: {
                    var wallet = $0
                    let lamports = inputAmount.toLamport(decimals: from.token.decimals)
                    wallet.lamports = (wallet.lamports ?? 0) - lamports
                    return wallet
                })
                
                // update destination wallet
                self?.walletsRepository.updateWallet(where: {$0.pubkey == to.pubkey}, transform: {
                    var wallet = $0
                    let lamports = estimatedAmount.toLamport(decimals: to.token.decimals)
                    wallet.lamports = (wallet.lamports ?? 0) + lamports
                    return wallet
                })
                
                // FIXME: - Remove transactionManager
                let transaction = Transaction(
                    signatureInfo: .init(signature: transactionId),
                    type: .send,
                    amount: -inputAmount,
                    symbol: from.token.symbol,
                    status: .processing
                )
                self?.transactionManager.process(transaction)
            }
        }
        
        private func executeCloseAccount(_ wallet: Wallet) {
            executeRequest { [weak self] transactionId in
                self?.walletsRepository.updateWallet(where: {$0.token.symbol == "SOL"}, transform: { [weak self] in
                    var wallet = $0
                    let lamports = self?.output.reimbursedAmount?.toLamport(decimals: wallet.token.decimals) ?? 0
                    wallet.lamports = (wallet.lamports ?? 0) + lamports
                    return wallet
                })
                
                self?.walletsRepository.removeItem(where: {$0.pubkey == wallet.pubkey})
                
                // FIXME: - Remove transactionManager
                let transaction = Transaction(
                    type: .send,
                    symbol: "SOL",
                    status: .processing
                )
                self?.transactionManager.process(transaction)
            }
        }
        
        private func executeRequest(completion: @escaping (SolanaSDK.TransactionID) -> Void) {
            // clean up
            self.transactionStatusSubject.accept(.processing)
            self.transactionIdSubject.accept(nil)
            
            // request
            request
                .flatMapCompletable { [weak self] transactionId in
                    // update status
                    self?.transactionStatusSubject.accept(.processing)
                    self?.transactionIdSubject.accept(transactionId)
                    
                    completion(transactionId)
                    
                    // observe confimation status
                    return self?.transactionHandler.observeTransactionCompletion(signature: transactionId) ?? .empty()
                }
                .subscribe(onCompleted: { [weak self] in
                    self?.transactionStatusSubject.accept(.confirmed)
                }, onError: { [weak self] error in
                    self?.transactionStatusSubject.accept(.error(error))
                })
                .disposed(by: disposeBag)
        }
    }
}
