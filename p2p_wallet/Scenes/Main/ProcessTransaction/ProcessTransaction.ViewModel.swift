//
//  ProcessTransaction.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ProcessTransactionResponseType {}
extension SolanaSDK.TransactionID: ProcessTransactionResponseType {}
extension SolanaSDK.SwapResponse: ProcessTransactionResponseType {}

extension ProcessTransaction {
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {}
        struct Output {
            let navigationScene: Driver<NavigatableScene>
            let transactionType: TransactionType
            let transaction: Driver<SolanaSDK.ParsedTransaction>
            let pricesRepository: PricesRepository
            var reimbursedAmount: Double?
        }
        
        // MARK: - Dependencies
        private let transactionType: TransactionType
        private let request: Single<ProcessTransactionResponseType>
        private let transactionHandler: ProcessingTransactionsRepository
        private let walletsRepository: WalletsRepository
        private let apiClient: ProcessTransactionAPIClient
        private let pricesRepository: PricesRepository
        private let analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        let input: Input
        var output: Output
        
        // MARK: - Subject
        private let navigationSubject = PublishSubject<NavigatableScene>()
        private let transactionSubject = BehaviorRelay<SolanaSDK.ParsedTransaction>(value: .init(status: .requesting, signature: nil, value: nil, slot: nil, blockTime: nil, fee: nil, blockhash: nil))
        
        // MARK: - Initializer
        init(
            transactionType: TransactionType,
            request: Single<ProcessTransactionResponseType>,
            transactionHandler: ProcessingTransactionsRepository,
            walletsRepository: WalletsRepository,
            pricesRepository: PricesRepository,
            apiClient: ProcessTransactionAPIClient,
            analyticsManager: AnalyticsManagerType
        ) {
            self.transactionType = transactionType
            self.request = request
            self.transactionHandler = transactionHandler
            self.walletsRepository = walletsRepository
            self.apiClient = apiClient
            self.pricesRepository = pricesRepository
            self.analyticsManager = analyticsManager
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: .showExplorer(transactionID: "")),
                transactionType: transactionType,
                transaction: transactionSubject
                    .asDriver(),
                pricesRepository: pricesRepository
            )
            
            execute()
        }
        
        // MARK: - Actions
        func fetchReimbursedAmountForClosingTransaction() -> Single<Double> {
            apiClient.getReimbursedAmountForClosingToken()
                .catchAndReturn(0)
                .do(onSuccess: {[weak self] amount in
                    self?.output.reimbursedAmount = amount
                })
        }
        
        @objc func execute() {
            var requestIndex: Int
            
            switch transactionType {
            case .send(let fromWallet, let receiver, let lamports, let fee):
                // form transaction
                let transaction = SolanaSDK.TransferTransaction(
                    source: fromWallet,
                    destination: Wallet(pubkey: receiver, lamports: 0, token: fromWallet.token),
                    authority: walletsRepository.nativeWallet?.pubkey,
                    destinationAuthority: nil,
                    amount: lamports.convertToBalance(decimals: fromWallet.token.decimals),
                    myAccount: fromWallet.pubkey
                )
                
                // Verify address
                guard NSRegularExpression.publicKey.matches(receiver) else {
                    var tx = transactionSubject.value
                    tx.value = transaction
                    tx.status = .error(L10n.wrongWalletAddress)
                    transactionSubject.accept(tx)
                    return
                }
                
                // Execute
                requestIndex = markAsRequestingAndSendRequest(transaction: transaction, fee: fee)
            case .swap(let from, let to, let inputAmount, let estimatedAmount, let fee):
                // form transaction
                let transaction = SolanaSDK.SwapTransaction(
                    source: from,
                    sourceAmount: inputAmount.convertToBalance(decimals: from.token.decimals),
                    destination: to,
                    destinationAmount: estimatedAmount.convertToBalance(decimals: to.token.decimals),
                    myAccountSymbol: nil
                )
                
                // Execute
                requestIndex = markAsRequestingAndSendRequest(transaction: transaction, fee: fee)
            case .closeAccount(let wallet):
                // form transaction
                let transaction = SolanaSDK.CloseAccountTransaction(
                    reimbursedAmount: output.reimbursedAmount,
                    closedWallet: wallet
                )
                
                // Execute
                requestIndex = markAsRequestingAndSendRequest(transaction: transaction, fee: 0)
            }
            
            // observe
            observeTransaction(requestIndex: requestIndex)
        }
        
        @objc func tryAgain() {
            // log
            var event: AnalyticsEvent?
            
            if let error = transactionSubject.value.status.getError()?.readableDescription
            {
                switch transactionType {
                case .send:
                    event = .sendTryAgainClick(error: error)
                case .swap:
                    event = .swapTryAgainClick(error: error)
                case .closeAccount:
                    break
                }
            }
            
            if let event = event {
                analyticsManager.log(event: event)
            }
            
            // execute
            execute()
        }
        
        @objc func showExplorer() {
            guard let id = transactionSubject.value.signature else {return}
            
            // log
            let transactionStatus = transactionSubject.value.status.rawValue
            switch transactionType {
            case .send:
                analyticsManager.log(event: .sendExplorerClick(txStatus: transactionStatus))
            case .swap:
                analyticsManager.log(event: .swapExplorerClick(txStatus: transactionStatus))
            case .closeAccount:
                break
            }
            
            // navigate
            navigationSubject.onNext(.showExplorer(transactionID: id))
        }
        
        @objc func done() {
            // log
            let transactionStatus = transactionSubject.value.status.rawValue
            switch transactionType {
            case .send:
                analyticsManager.log(event: .sendDoneClick(txStatus: transactionStatus))
            case .swap:
                analyticsManager.log(event: .swapDoneClick(txStatus: transactionStatus))
            case .closeAccount:
                break
            }
            
            // navigate
            navigationSubject.onNext(.done)
        }
        
        @objc func cancel() {
            // log
            var event: AnalyticsEvent?
            
            if let error = transactionSubject.value.status.getError()?.readableDescription
            {
                switch transactionType {
                case .send:
                    event = .sendCancelClick(error: error)
                case .swap:
                    event = .swapCancelClick(error: error)
                case .closeAccount:
                    break
                }
            }
            
            if let event = event {
                analyticsManager.log(event: event)
            }
            
            // cancel
            navigationSubject.onNext(.cancel)
        }
        
        // MARK: - Helpers
        /// Mark transaction as processing, then call request
        /// - Parameters:
        ///   - transaction: transaction that need to be sent
        ///   - fee: transaction's fee
        /// - Returns: transaction index in repository (for observing)
        private func markAsRequestingAndSendRequest(transaction: AnyHashable, fee: SolanaSDK.Lamports) -> Int {
            // mark as requesting
            var tx = transactionSubject.value
            tx.status = .requesting
            tx.value = transaction
            transactionSubject.accept(tx)
            
            // send transaction
            return transactionHandler.request(request, transaction: transactionSubject.value, fee: fee)
        }
        
        /// Observe status of current transaction
        /// - Parameter requestIndex: index of current transaction in repository
        private func observeTransaction(requestIndex: Int) {
            transactionHandler.processingTransactionsObservable()
                .map {$0[safe: requestIndex]}
                .filter {$0 != nil}
                .map {$0!}
                .bind(to: transactionSubject)
                .disposed(by: disposeBag)
        }
    }
}
