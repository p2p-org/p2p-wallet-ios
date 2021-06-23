//
//  WalletDetail.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension WalletDetail {
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {
            let walletName = PublishRelay<String>()
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene?>
            let wallet: Driver<Wallet?>
            let solPubkey: Driver<String?>
            let graphViewModel: WalletGraphViewModel
            let transactionsViewModel: TransactionsViewModel
        }
        
        // MARK: - Dependencies
        private let walletsRepository: WalletsRepository
        private let pubkey: String
        private let symbol: String
        let analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        let input: Input
        let output: Output
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        
        // MARK: - Initializer
        init(
            pubkey: String,
            symbol: String,
            walletsRepository: WalletsRepository,
            pricesRepository: PricesRepository,
            transactionsRepository: TransactionsRepository,
            analyticsManager: AnalyticsManagerType,
            feeRelayerAPIClient: FeeRelayerSolanaAPIClient
        ) {
            self.pubkey = pubkey
            self.symbol = symbol
            self.walletsRepository = walletsRepository
            self.analyticsManager = analyticsManager
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: nil),
                wallet: walletSubject
                    .asDriver(),
                solPubkey: walletsRepository.dataObservable
                    .map {$0?.first(where: {$0.token.symbol == "SOL"})}
                    .map {$0?.pubkey}
                    .asDriver(onErrorJustReturn: nil),
                graphViewModel: WalletGraphViewModel(
                    symbol: symbol,
                    pricesRepository: pricesRepository
                ),
                transactionsViewModel: TransactionsViewModel(
                    account: pubkey,
                    accountSymbol: symbol,
                    repository: transactionsRepository,
                    pricesRepository: pricesRepository,
                    feeRelayerAPIClient: feeRelayerAPIClient
                )
            )
            
            bind()
        }
        
        /// Bind subjects
        private func bind() {
            bindInputIntoSubjects()
            bindSubjectsIntoSubjects()
        }
        
        private func bindInputIntoSubjects() {
            input.walletName
                .subscribe(onNext: {[weak self] newName in
                    self?.renameWallet(to: newName)
                })
                .disposed(by: disposeBag)
        }
        
        private func bindSubjectsIntoSubjects() {
            walletsRepository
                .dataObservable
                .map {$0?.first(where: {$0.pubkey == self.pubkey})}
                .do(onNext: {[weak self] wallet in
                    guard let ticker = wallet?.token.symbol else {return}
                    self?.analyticsManager.log(event: .tokenDetailsOpen(tokenTicker: ticker))
                })
                .bind(to: walletSubject)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc func showWalletSettings() {
            guard let pubkey = walletSubject.value?.pubkey else {return}
            navigationSubject.accept(.settings(walletPubkey: pubkey))
        }
        
        @objc func sendTokens() {
            guard let wallet = walletSubject.value else {return}
            analyticsManager.log(event: .tokenDetailsSendClick)
            analyticsManager.log(event: .sendOpen(fromPage: "token_details"))
            navigationSubject.accept(.send(wallet: wallet))
        }
        
        @objc func receiveTokens() {
            guard let pubkey = walletSubject.value?.pubkey else {return}
            analyticsManager.log(event: .tokenDetailQrClick)
            analyticsManager.log(event: .tokenDetailsReceiveClick)
            analyticsManager.log(event: .receiveOpen(fromPage: "token_details"))
            navigationSubject.accept(.receive(walletPubkey: pubkey))
        }
        
        @objc func swapTokens() {
            guard let wallet = walletSubject.value else {return}
            analyticsManager.log(event: .tokenDetailsSwapClick)
            analyticsManager.log(event: .swapOpen(fromPage: "token_details"))
            navigationSubject.accept(.swap(fromWallet: wallet))
        }
        
        func showTransaction(_ transaction: SolanaSDK.AnyTransaction) {
            analyticsManager.log(event: .tokenDetailsDetailsOpen)
            navigationSubject.accept(.transactionInfo(transaction))
        }
        
        // MARK: - Helpers
        private func renameWallet(to newName: String) {
            guard let wallet = walletSubject.value else {return}
            
            var newName = newName
            if newName.isEmpty {
                // fall back to wallet name
                newName = wallet.name
            }
            
            walletsRepository.updateWallet(wallet, withName: newName)
        }
    }
}
