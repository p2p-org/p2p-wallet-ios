//
//  WalletDetail.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol WalletDetailViewModelType {
    var navigatableSceneDriver: Driver<WalletDetail.NavigatableScene?> {get}
    var walletDriver: Driver<Wallet?> {get}
    var nativePubkey: Driver<String?> {get}
    var graphViewModel: WalletGraphViewModel {get}
    var transactionsViewModel: TransactionsViewModel {get}
    var canBuyToken: Bool {get}
    
    func renameWallet(to newName: String)
    func showWalletSettings()
    func sendTokens()
    func buyTokens()
    func receiveTokens()
    func swapTokens()
    func showTransaction(_ transaction: SolanaSDK.ParsedTransaction)
    func tokenDetailsActivityDidScroll(to pageNum: Int)
}

extension WalletDetail {
    class ViewModel {
        // MARK: - Dependencies
        private let walletsRepository: WalletsRepository
        private let pricesService: PricesServiceType
        private let processingTransactionRepository: ProcessingTransactionsRepository
        private let transactionsRepository: TransactionsRepository
        private let notificationsRepository: WLNotificationsRepository
        private let feeRelayer: FeeRelayerType
        private let pubkey: String
        private let symbol: String
        @Injected var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        lazy var graphViewModel: WalletGraphViewModel = {
            WalletGraphViewModel(
                symbol: symbol,
                pricesService: pricesService
            )
        }()
        
        lazy var transactionsViewModel = TransactionsViewModel(
            account: pubkey,
            accountSymbol: symbol,
            repository: transactionsRepository,
            pricesService: pricesService,
            processingTransactionRepository: processingTransactionRepository,
            feeRelayer: feeRelayer,
            notificationsRepository: notificationsRepository
        )
        
        // MARK: - Subject
        private let navigatableSceneSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        
        // MARK: - Initializer
        init(
            pubkey: String,
            symbol: String,
            walletsRepository: WalletsRepository,
            processingTransactionRepository: ProcessingTransactionsRepository,
            pricesService: PricesServiceType,
            transactionsRepository: TransactionsRepository,
            feeRelayer: FeeRelayerType,
            notificationsRepository: WLNotificationsRepository
        ) {
            self.pubkey = pubkey
            self.symbol = symbol
            self.walletsRepository = walletsRepository
            self.pricesService = pricesService
            self.processingTransactionRepository = processingTransactionRepository
            self.transactionsRepository = transactionsRepository
            self.feeRelayer = feeRelayer
            self.notificationsRepository = notificationsRepository
            
            bind()
        }
        
        /// Bind subjects
        private func bind() {
            bindSubjectsIntoSubjects()
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
    }
}

extension WalletDetail.ViewModel: WalletDetailViewModelType {
    var navigatableSceneDriver: Driver<WalletDetail.NavigatableScene?> {
        navigatableSceneSubject.asDriver()
    }
    
    var walletDriver: Driver<Wallet?> {
        walletSubject.asDriver()
    }
    
    var nativePubkey: Driver<String?> {
        walletsRepository.dataObservable
            .map {$0?.first(where: {$0.isNativeSOL})}
            .map {$0?.pubkey}
            .asDriver(onErrorJustReturn: nil)
    }
    
    var canBuyToken: Bool { BuyProviderType.default.isSupported(symbol: symbol) }
    
    // MARK: - Actions
    func showWalletSettings() {
        guard let pubkey = walletSubject.value?.pubkey else {return}
        navigatableSceneSubject.accept(.settings(walletPubkey: pubkey))
    }
    
    func renameWallet(to newName: String) {
        guard let wallet = walletSubject.value else {return}
        
        var newName = newName
        if newName.isEmpty {
            // fall back to wallet name
            newName = wallet.name
        }
        
        walletsRepository.updateWallet(wallet, withName: newName)
    }
    
    func sendTokens() {
        guard let wallet = walletSubject.value else {return}
        analyticsManager.log(event: .tokenDetailsSendClick)
        analyticsManager.log(event: .sendOpen(fromPage: "token_details"))
        navigatableSceneSubject.accept(.send(wallet: wallet))
    }
    
    func buyTokens() {
        var tokens = BuyProviders.Crypto.eth
        if symbol == "SOL" {
            tokens = .sol
        }
        if symbol == "USDT" {
            tokens = .usdt
        }
        analyticsManager.log(event: .tokenDetailsBuyClick)
        navigatableSceneSubject.accept(.buy(tokens: tokens))
    }
    
    func receiveTokens() {
        guard let pubkey = walletSubject.value?.pubkey else {return}
        analyticsManager.log(event: .tokenDetailQrClick)
        analyticsManager.log(event: .tokenDetailsReceiveClick)
        analyticsManager.log(event: .receiveOpen(fromPage: "token_details"))
        navigatableSceneSubject.accept(.receive(walletPubkey: pubkey))
    }
    
    func swapTokens() {
        guard let wallet = walletSubject.value else {return}
        analyticsManager.log(event: .tokenDetailsSwapClick)
        analyticsManager.log(event: .swapOpen(fromPage: "token_details"))
        navigatableSceneSubject.accept(.swap(fromWallet: wallet))
    }
    
    func showTransaction(_ transaction: SolanaSDK.ParsedTransaction) {
        analyticsManager.log(event: .tokenDetailsDetailsOpen)
        navigatableSceneSubject.accept(.transactionInfo(transaction))
    }
    
    func tokenDetailsActivityDidScroll(to pageNum: Int) {
        analyticsManager.log(event: .tokenDetailsActivityScroll(pageNum: pageNum))
    }
}
