//
//  WalletDetail.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxSwift
import RxCocoa
import TransakSwift

extension WalletDetail {
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {
            let walletName = PublishRelay<String>()
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene?>
            let wallet: Driver<Wallet?>
            let nativePubkey: Driver<String?>
            let graphViewModel: WalletGraphViewModel
            let transactionsViewModel: TransactionsViewModel
            let canBuyToken: Bool
        }
        
        // MARK: - Dependencies
        private let walletsRepository: WalletsRepository
        private let processingTransactionRepository: ProcessingTransactionsRepository
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
            processingTransactionRepository: ProcessingTransactionsRepository,
            pricesRepository: PricesRepository,
            transactionsRepository: TransactionsRepository,
            analyticsManager: AnalyticsManagerType,
            feeRelayer: FeeRelayerType,
            notificationsRepository: WLNotificationsRepository
        ) {
            self.pubkey = pubkey
            self.symbol = symbol
            self.walletsRepository = walletsRepository
            self.processingTransactionRepository = processingTransactionRepository
            self.analyticsManager = analyticsManager
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: nil),
                wallet: walletSubject
                    .asDriver(),
                nativePubkey: walletsRepository.dataObservable
                    .map {$0?.first(where: {$0.token.isNative})}
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
                    processingTransactionRepository: processingTransactionRepository,
                    feeRelayer: feeRelayer,
                    notificationsRepository: notificationsRepository
                ),
                canBuyToken: symbol == "SOL" || symbol == "USDC"
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
                .filter {$0 != nil}
                .bind(to: walletSubject)
                .disposed(by: disposeBag)
            
            walletSubject
                .filter {$0 != nil}
                .map {$0!.token.symbol}
                .take(1)
                .asSingle()
                .subscribe(onSuccess: {[weak self] ticker in
                    self?.analyticsManager.log(event: .tokenDetailsOpen(tokenTicker: ticker))
                })
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
        
        @objc func buyTokens() {
            var tokens = TransakWidgetViewController.CryptoCurrency.all
            if symbol == "SOL" {
                tokens = .sol
            }
            if symbol == "USDC" {
                tokens = .usdc
            }
            analyticsManager.log(event: .tokenDetailsBuyClick)
            navigationSubject.accept(.buy(tokens: tokens))
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
        
        func showTransaction(_ transaction: SolanaSDK.ParsedTransaction) {
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
