//
//  ProcessTransaction.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ProcessTransactionViewModelType {
    var transactionType: ProcessTransaction.TransactionType {get}
    var pricesService: PricesServiceType {get}
    var reimbursedAmount: Double? {get}
    
    var navigatableSceneDriver: Driver<ProcessTransaction.NavigatableScene?> {get}
    var transactionDriver: Driver<SolanaSDK.ParsedTransaction> {get}
    
    func fetchReimbursedAmountForClosingTransaction() -> Single<Double>
    func showExplorer()
    func markAsDone()
    func tryAgain()
    func cancel()
}

extension ProcessTransaction {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var transactionHandler: ProcessingTransactionsRepository
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var apiClient: ProcessTransactionAPIClient
        @Injected var pricesService: PricesServiceType
        
        // MARK: - Properties
        let transactionType: TransactionType
        
        private let disposeBag = DisposeBag()
        private(set) var reimbursedAmount: Double?
        private let request: Single<ProcessTransactionResponseType>
        
        // MARK: - Subject
        private let navigatableSceneSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let transactionSubject = BehaviorRelay<SolanaSDK.ParsedTransaction>(value: .init(status: .requesting, signature: nil, value: nil, slot: nil, blockTime: nil, fee: nil, blockhash: nil))
        
        // MARK: - Initializer
        init(
            transactionType: TransactionType,
            request: Single<ProcessTransactionResponseType>
        ) {
            self.transactionType = transactionType
            self.request = request
            execute()
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        @objc func execute() {
            var requestIndex: Int
            
            switch transactionType {
            case .send(let fromWallet, let receiver, let lamports, let networkFee):
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
                if !NSRegularExpression.publicKey.matches(receiver) && !fromWallet.token.isRenBTC && !receiver.hasSuffix(.nameServiceDomain) {
                    var tx = transactionSubject.value
                    tx.value = transaction
                    tx.status = .error(L10n.wrongWalletAddress)
                    transactionSubject.accept(tx)
                    return
                }
                
                // Execute
                requestIndex = markAsRequestingAndSendRequest(
                    transaction: transaction,
                    fees: [
                        .init(type: .transactionFee, lamports: networkFee, token: .nativeSolana, toString: nil)
                    ]
                )
            case .orcaSwap(let from, let to, let inputAmount, let estimatedAmount, let fees):
                // form transaction
                let transaction = SolanaSDK.SwapTransaction(
                    source: from,
                    sourceAmount: inputAmount.convertToBalance(decimals: from.token.decimals),
                    destination: to,
                    destinationAmount: estimatedAmount.convertToBalance(decimals: to.token.decimals),
                    myAccountSymbol: nil
                )
                
                // Execute
                requestIndex = markAsRequestingAndSendRequest(
                    transaction: transaction,
                    fees: fees
                )
                
//            case .swap(let provider, let from, let to, let inputAmount, let estimatedAmount, let fees, let slippage, let isSimulation):
//                // form transaction
//                let transaction = SolanaSDK.SwapTransaction(
//                    source: from,
//                    sourceAmount: inputAmount,
//                    destination: to,
//                    destinationAmount: estimatedAmount,
//                    myAccountSymbol: nil
//                )
//                
//                // Execute
//                requestIndex = markAsRequestingAndSendRequest(
//                    transaction: transaction,
//                    fees: fees,
//                    overridingRequest: provider
//                        .swap(
//                            fromWallet: from,
//                            toWallet: to,
//                            amount: inputAmount,
//                            slippage: slippage,
//                            isSimulation: isSimulation
//                        )
//                        .map {$0 as ProcessTransactionResponseType}
//                )
                
            case .closeAccount(let wallet):
                // form transaction
                let transaction = SolanaSDK.CloseAccountTransaction(
                    reimbursedAmount: reimbursedAmount,
                    closedWallet: wallet
                )
                
                // Execute
                requestIndex = markAsRequestingAndSendRequest(
                    transaction: transaction,
                    fees: [.init(type: .transactionFee, lamports: 0, token: .nativeSolana, toString: nil)]
                )
            }
            
            // observe
            observeTransaction(requestIndex: requestIndex)
        }
        
        // MARK: - Helpers
        /// Mark transaction as processing, then call request
        /// - Parameters:
        ///   - transaction: transaction that need to be sent
        ///   - fee: transaction's fee
        /// - Returns: transaction index in repository (for observing)
        private func markAsRequestingAndSendRequest(
            transaction: AnyHashable,
            fees: [PayingFee],
            overridingRequest: Single<ProcessTransactionResponseType>? = nil
        ) -> Int {
            // mark as requesting
            var tx = transactionSubject.value
            tx.status = .requesting
            tx.value = transaction
            transactionSubject.accept(tx)
            
            // send transaction
            return transactionHandler.request(overridingRequest ?? request, transaction: transactionSubject.value, fees: fees)
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

extension ProcessTransaction.ViewModel: ProcessTransactionViewModelType {
    var navigatableSceneDriver: Driver<ProcessTransaction.NavigatableScene?> {
        navigatableSceneSubject.asDriver()
    }
    
    var transactionDriver: Driver<SolanaSDK.ParsedTransaction> {
        transactionSubject.asDriver()
    }
    
    // MARK: - Actions
    func fetchReimbursedAmountForClosingTransaction() -> Single<Double> {
        apiClient.getReimbursedAmountForClosingToken()
            .catchAndReturn(0)
            .do(onSuccess: {[weak self] amount in
                self?.reimbursedAmount = amount
            })
    }
    
    func showExplorer() {
        guard let id = transactionSubject.value.signature else {return}
        
        // log
        let transactionStatus = transactionSubject.value.status.rawValue
        switch transactionType {
        case .send:
            analyticsManager.log(event: .sendExplorerClick(txStatus: transactionStatus))
        case .orcaSwap:
            analyticsManager.log(event: .swapExplorerClick(txStatus: transactionStatus))
        case .closeAccount:
            break
        }
        
        // navigate
        navigatableSceneSubject.accept(.showExplorer(transactionID: id))
    }
    
    func markAsDone() {
        // log
        let transactionStatus = transactionSubject.value.status.rawValue
        switch transactionType {
        case .send:
            analyticsManager.log(event: .sendDoneClick(txStatus: transactionStatus))
        case .orcaSwap:
            analyticsManager.log(event: .swapDoneClick(txStatus: transactionStatus))
        case .closeAccount:
            break
        }
        
        // navigate
        navigatableSceneSubject.accept(.done)
    }
    
    func tryAgain() {
        // log
        var event: AnalyticsEvent?
        
        if let error = transactionSubject.value.status.getError()?.readableDescription
        {
            switch transactionType {
            case .send:
                event = .sendTryAgainClick(error: error)
            case .orcaSwap:
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
    
    func cancel() {
        // log
        var event: AnalyticsEvent?
        
        if let error = transactionSubject.value.status.getError()?.readableDescription
        {
            switch transactionType {
            case .send:
                event = .sendCancelClick(error: error)
            case .orcaSwap:
                event = .swapCancelClick(error: error)
            case .closeAccount:
                break
            }
        }
        
        if let event = event {
            analyticsManager.log(event: event)
        }
        
        // cancel
        navigatableSceneSubject.accept(.cancel)
    }
}
