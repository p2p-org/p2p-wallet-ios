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
            case .send(let fromWallet, let receiver, let amount):
                executeSend(fromWallet: fromWallet, receiver: receiver, amount: amount)
            case .swap(let from, let to, let inputAmount, let estimatedAmount):
                executeSwap(from: from, to: to, inputAmount: inputAmount, estimatedAmount: estimatedAmount)
            case .closeAccount(let wallet):
                executeCloseAccount(wallet)
            }
        }
        
        @objc func tryAgain() {
            // log
            var event: AnalyticsEvent?
            switch transactionType {
            case .send:
                event = .sendTryAgainClick
            case .swap:
                event = .swapTryAgainClick
            case .closeAccount:
                break
            }
            
            if let event = event,
               let error = transactionStatusSubject.value.getError()?.readableDescription
            {
                analyticsManager.log(event: event, params: ["error": error])
            }
            
            // execute
            executeRequest()
        }
        
        @objc func showExplorer() {
            guard let id = transactionIdSubject.value else {return}
            
            // log
            let transactionConfirmed = (transactionStatusSubject.value == .confirmed)
            switch transactionType {
            case .send:
                analyticsManager.log(event: .sendExplorerClick, params: ["transactionConfirmed": transactionConfirmed])
            case .swap:
                analyticsManager.log(event: .swapExplorerClick, params: ["transactionConfirmed": transactionConfirmed])
            case .closeAccount:
                break
            }
            
            // navigate
            navigationSubject.onNext(.showExplorer(transactionID: id))
        }
        
        @objc func done() {
            // log
            let transactionConfirmed = (transactionStatusSubject.value == .confirmed)
            switch transactionType {
            case .send:
                analyticsManager.log(event: .sendCloseClick, params: ["transactionConfirmed": transactionConfirmed])
                analyticsManager.log(event: .sendDoneClick, params: ["transactionConfirmed": transactionConfirmed])
            case .swap:
                analyticsManager.log(event: .swapCloseClick, params: ["transactionConfirmed": transactionConfirmed])
                analyticsManager.log(event: .swapDoneClick, params: ["transactionConfirmed": transactionConfirmed])
            case .closeAccount:
                break
            }
            
            // navigate
            navigationSubject.onNext(.done)
        }
        
        @objc func cancel() {
            // log
            var event: AnalyticsEvent?
            switch transactionType {
            case .send:
                event = .sendCancelClick
            case .swap:
                event = .swapCancelClick
            case .closeAccount:
                break
            }
            
            if let event = event,
               let error = transactionStatusSubject.value.getError()?.readableDescription
            {
                analyticsManager.log(event: event, params: ["error": error])
            }
            
            // cancel
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
            executeRequest { [weak self] _ in
                // update wallet
                self?.walletsRepository.updateWallet(where: {$0.pubkey == fromWallet.pubkey}, transform: {
                    var wallet = $0
                    let lamports = amount.toLamport(decimals: fromWallet.token.decimals)
                    wallet.lamports = (wallet.lamports ?? 0) - lamports
                    return wallet
                })
            }
        }
        
        private func executeSwap(
            from: Wallet,
            to: Wallet,
            inputAmount: Double,
            estimatedAmount: Double
        ) {
            executeRequest { [weak self] response in
                // cast type
                let response = response as! SolanaSDK.SwapResponse
                
                // update source wallet
                self?.walletsRepository.updateWallet(where: {$0.pubkey == from.pubkey}, transform: {
                    var wallet = $0
                    let lamports = inputAmount.toLamport(decimals: from.token.decimals)
                    wallet.lamports = (wallet.lamports ?? 0) - lamports
                    return wallet
                })
                
                // update destination wallet
                if self?.walletsRepository.getWallets().contains(where: {$0.pubkey == to.pubkey}) == true
                {
                    self?.walletsRepository.updateWallet(where: {$0.pubkey == to.pubkey}, transform: {
                        var wallet = $0
                        let lamports = estimatedAmount.toLamport(decimals: to.token.decimals)
                        wallet.lamports = (wallet.lamports ?? 0) + lamports
                        return wallet
                    })
                } else if let pubkey = response.newWalletPubkey {
                    var wallet = to
                    wallet.pubkey = pubkey
                    wallet.lamports = estimatedAmount.toLamport(decimals: wallet.token.decimals)
                    
                    _ = self?.walletsRepository.insert(wallet)
                    
                    self?.pricesRepository.fetchCurrentPrices(coins: [wallet.token.symbol])
                }
            }
        }
        
        private func executeCloseAccount(_ wallet: Wallet) {
            executeRequest { [weak self] _ in
                self?.walletsRepository.updateWallet(where: {$0.token.symbol == "SOL"}, transform: { [weak self] in
                    var wallet = $0
                    let lamports = self?.output.reimbursedAmount?.toLamport(decimals: wallet.token.decimals) ?? 0
                    wallet.lamports = (wallet.lamports ?? 0) + lamports
                    return wallet
                })
                
                _ = self?.walletsRepository.removeItem(where: {$0.pubkey == wallet.pubkey})
            }
        }
        
        private func executeRequest(completion: @escaping (ProcessTransactionResponseType) -> Void) {
            // clean up
            self.transactionStatusSubject.accept(.processing)
            self.transactionIdSubject.accept(nil)
            
            // request
            request
                .map { response -> String in
                    if let swapResponse = response as? SolanaSDK.SwapResponse {
                        completion(swapResponse)
                        return swapResponse.transactionId
                    }
                    
                    if let response = response as? SolanaSDK.TransactionID {
                        completion(response)
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
