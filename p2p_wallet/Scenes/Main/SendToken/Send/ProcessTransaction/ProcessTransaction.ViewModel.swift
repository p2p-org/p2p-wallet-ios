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
    enum NavigatableScene {
        case showExplorer(transactionID: String)
        case done
        case cancel
    }
    
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {}
        struct Output {
            let navigationScene: Driver<NavigatableScene>
            let transactionId: Driver<SolanaSDK.TransactionID?>
            let transactionType: TransactionType
            let transactionStatus: Driver<TransactionStatus>
            let pricesRepository: PricesRepository
        }
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private let transactionType: TransactionType
        private let request: Single<SolanaSDK.TransactionID>
        private let transactionHandler: TransactionHandler
        private let transactionManager: TransactionsManager
        private let walletsRepository: WalletsRepository
        
        let input: Input
        let output: Output
        
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
            pricesRepository: PricesRepository
        ) {
            self.transactionType = transactionType
            self.request = request
            self.transactionHandler = transactionHandler
            self.transactionManager = transactionManager
            self.walletsRepository = walletsRepository
            
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
        @objc func executeRequest() {
            switch transactionType {
            case .send(let fromWallet, let receiver, let amount):
                executeSend(fromWallet: fromWallet, receiver: receiver, amount: amount)
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
        func executeSend(fromWallet: Wallet, receiver: String, amount: Double) {
            // Verify address
            guard NSRegularExpression.publicKey.matches(receiver) else {
                transactionStatusSubject
                    .accept(.error(SolanaSDK.Error.other(L10n.wrongWalletAddress)))
                return
            }
            
            // request
            request
                .flatMapCompletable { [weak self] transactionId in
                    // update status
                    self?.transactionStatusSubject.accept(.processing)
                    self?.transactionIdSubject.accept(transactionId)
                    
                    // update wallet
                    self?.walletsRepository.updateWallet(where: {$0.pubkey == fromWallet.pubkey}, transform: {
                        var wallet = $0
                        let lamports = amount.toLamport(decimals: fromWallet.token.decimals)
                        wallet.lamports = (wallet.lamports ?? 0) - lamports
                        return wallet
                    })
                    
                    // FIX ME: - Remove transactionManager
                    let transaction = Transaction(
                        signatureInfo: .init(signature: transactionId),
                        type: .send,
                        amount: -amount,
                        symbol: fromWallet.token.symbol,
                        status: .processing
                    )
                    self?.transactionManager.process(transaction)
                    
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
