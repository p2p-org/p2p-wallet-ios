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
            let transactionId: Driver<SolanaSDK.TransactionID?>
            let transactionType: TransactionType
            let transactionStatus: Driver<TransactionStatus>
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
        private let transactionIdSubject = BehaviorRelay<SolanaSDK.TransactionID?>(value: nil)
        private let transactionStatusSubject = BehaviorRelay<TransactionStatus>(value: .processing)
        
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
            case .send(let fromWallet, let receiver, let lamports, let feeInLamports):
                executeSend(fromWallet: fromWallet, receiver: receiver, lamports: lamports, feeInLamports: feeInLamports)
            case .swap(let from, let to, let inputAmount, let estimatedAmount, let fee):
                executeSwap(from: from, to: to, inputAmount: inputAmount, estimatedAmount: estimatedAmount, fee: fee)
            case .closeAccount(let wallet):
                executeCloseAccount(wallet)
            }
        }
        
        @objc func tryAgain() {
            // log
            var event: AnalyticsEvent?
            
            if let error = transactionStatusSubject.value.getError()?.readableDescription
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
            executeRequest()
        }
        
        @objc func showExplorer() {
            guard let id = transactionIdSubject.value else {return}
            
            // log
            let transactionStatus = transactionStatusSubject.value.rawValue
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
            let transactionStatus = transactionStatusSubject.value.rawValue
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
            
            if let error = transactionStatusSubject.value.getError()?.readableDescription
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
        private func executeSend(
            fromWallet: Wallet,
            receiver: String,
            lamports: SolanaSDK.Lamports,
            feeInLamports: SolanaSDK.Lamports
        ) {
            // Verify address
            guard NSRegularExpression.publicKey.matches(receiver) else {
                transactionStatusSubject
                    .accept(.error(SolanaSDK.Error.other(L10n.wrongWalletAddress)))
                return
            }
            
            // Execute request
            executeRequest { [weak self] _ in
                // update wallet
                self?.walletsRepository.batchUpdate(closure: {
                    var wallets = $0
                    // update wallet
                    if let index = wallets.firstIndex(where: {$0.pubkey == fromWallet.pubkey})
                    {
                        wallets[index].decreaseBalance(diffInLamports: lamports)
                    }
                    
                    // update SOL wallet (minus fee)
                    if let index = wallets.firstIndex(where: {$0.token.isNative})
                    {
                        wallets[index].decreaseBalance(diffInLamports: feeInLamports)
                    }
                    return wallets
                })
            }
        }
        
        private func executeSwap(
            from: Wallet,
            to: Wallet,
            inputAmount: SolanaSDK.Lamports,
            estimatedAmount: SolanaSDK.Lamports,
            fee: SolanaSDK.Lamports
        ) {
            executeRequest { [weak self] response in
                // cast type
                let response = response as! SolanaSDK.SwapResponse
                
                // batch update
                self?.walletsRepository.batchUpdate(closure: {
                    var wallets = $0
                    
                    // update source wallet
                    if let index = wallets.firstIndex(where: {$0.pubkey == from.pubkey})
                    {
                        wallets[index].decreaseBalance(diffInLamports: inputAmount)
                    }
                    
                    // update destination wallet if exists
                    if let index = wallets.firstIndex(where: {$0.pubkey == to.pubkey})
                    {
                        wallets[index].increaseBalance(diffInLamports: estimatedAmount)
                    }
                    
                    // add new wallet if destination is a new wallet
                    else if let pubkey = response.newWalletPubkey {
                        var wallet = to
                        wallet.pubkey = pubkey
                        wallet.lamports = estimatedAmount
                        wallets.append(wallet)
                    }
                    
                    // update sol wallet (minus fee)
                    if let index = wallets.firstIndex(where: {$0.token.isNative})
                    {
                        wallets[index].decreaseBalance(diffInLamports: fee)
                    }
                    
                    return wallets
                })
            }
        }
        
        private func executeCloseAccount(_ wallet: Wallet) {
            executeRequest { [weak self] _ in
                self?.walletsRepository.batchUpdate(closure: {
                    var wallets = $0
                    
                    // remove closed wallet
                    wallets.removeAll(where: {$0.pubkey == wallet.pubkey})
                    
                    // update sol wallet
                    if let index = wallets.firstIndex(where: {$0.token.isNative})
                    {
                        wallets[index].updateBalance(diff: self?.output.reimbursedAmount ?? 0)
                    }
                    
                    return wallets
                })
            }
        }
        
        private func executeRequest(completion: @escaping (ProcessTransactionResponseType) -> Void) {
            // clean up
            self.transactionStatusSubject.accept(.processing)
            self.transactionIdSubject.accept(nil)
            
            // request
            request
                .do(onSuccess: completion)
                .map { response -> String in
                    if let swapResponse = response as? SolanaSDK.SwapResponse {
                        return swapResponse.transactionId
                    }
                    
                    if let response = response as? SolanaSDK.TransactionID {
                        return response
                    }
                    
                    throw SolanaSDK.Error.unknown
                }
                .flatMapCompletable { [weak self] transactionId in
                    // update status
                    self?.transactionStatusSubject.accept(.processing)
                    self?.transactionIdSubject.accept(transactionId)
                    
                    // observe confimation status
                    return self?.transactionHandler.process(signature: transactionId) ?? .empty()
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
