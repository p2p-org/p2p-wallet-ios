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
    var walletsRepository: WalletsRepository {get}
    var navigatableSceneDriver: Driver<WalletDetail.NavigatableScene?> {get}
    var walletDriver: Driver<Wallet?> {get}
    var walletActionsDriver: Driver<[WalletActionType]> {get}
    var nativePubkey: Driver<String?> {get}
    var graphViewModel: WalletGraphViewModel {get}
    var transactionsViewModel: TransactionsViewModel {get}
    var canBuyToken: Bool {get}
    
    func renameWallet(to newName: String)
    func showWalletSettings()
    func start(action: WalletActionType)
    func showTransaction(_ transaction: SolanaSDK.ParsedTransaction)
    func tokenDetailsActivityDidScroll(to pageNum: Int)
}

extension WalletDetail {
    class ViewModel {
        // MARK: - Dependencies
        @Injected var walletsRepository: WalletsRepository
        @Injected private var pricesService: PricesServiceType
        @Injected private var processingTransactionRepository: ProcessingTransactionsRepository
        @Injected private var transactionsRepository: TransactionsRepository
        @Injected private var notificationsRepository: WLNotificationsRepository
        private let pubkey: String
        private let symbol: String
        @Injected var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        lazy var graphViewModel = WalletGraphViewModel(symbol: symbol)
        
        lazy var transactionsViewModel = TransactionsViewModel(
            account: pubkey,
            accountSymbol: symbol
        )
        
        // MARK: - Subject
        private let navigatableSceneSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        private lazy var walletActionsSubject = walletSubject
            .map { wallet -> [WalletActionType] in
                guard let wallet = wallet else { return [] }

                if wallet.isNativeSOL {
                    return [/*.buy, */.receive, .send, .swap]
                } else {
                    return [.receive, .send, .swap]
                }
            }

        // MARK: - Initializer
        init(pubkey: String, symbol: String) {
            self.pubkey = pubkey
            self.symbol = symbol
            bind()
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        /// Bind subjects
        private func bind() {
            bindSubjectsIntoSubjects()
        }
        
        private func bindSubjectsIntoSubjects() {
            walletsRepository
                .dataObservable
                .map {[weak self] in $0?.first(where: {$0.pubkey == self?.pubkey})}
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

        private func sendTokens() {
            guard let wallet = walletSubject.value else {return}
            analyticsManager.log(event: .tokenDetailsSendClick)
            analyticsManager.log(event: .sendViewed(lastScreen: "token_details"))
            navigatableSceneSubject.accept(.send(wallet: wallet))
        }

        private func buyTokens() {
            var tokens = Buy.CryptoCurrency.eth
            if symbol == "SOL" {
                tokens = .sol
            }
            if symbol == "USDT" {
                tokens = .usdt
            }
            analyticsManager.log(event: .tokenDetailsBuyClick)
            navigatableSceneSubject.accept(.buy(tokens: tokens))
        }

        private func receiveTokens() {
            guard let pubkey = walletSubject.value?.pubkey else {return}
            analyticsManager.log(event: .tokenDetailQrClick)
            analyticsManager.log(event: .tokenReceiveViewed)
            analyticsManager.log(event: .receiveViewed(fromPage: "token_details"))
            navigatableSceneSubject.accept(.receive(walletPubkey: pubkey))
        }

        private func swapTokens() {
            guard let wallet = walletSubject.value else {return}
            analyticsManager.log(event: .tokenDetailsSwapClick)
            analyticsManager.log(event: .swapViewed(lastScreen: "token_details"))
            navigatableSceneSubject.accept(.swap(fromWallet: wallet))
        }

    }
}

extension WalletDetail.ViewModel: WalletDetailViewModelType {
    var walletActionsDriver: Driver<[WalletActionType]> {
        walletActionsSubject
            .asDriver(onErrorJustReturn: [])
    }

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

    func start(action: WalletActionType) {
        switch action {
        case .receive:
            receiveTokens()
        case .buy:
            buyTokens()
        case .send:
            sendTokens()
        case .swap:
            swapTokens()
        }
    }

    func showTransaction(_ transaction: SolanaSDK.ParsedTransaction) {
        analyticsManager.log(event: .tokenDetailsDetailsOpen)
        navigatableSceneSubject.accept(.transactionInfo(transaction))
    }
    
    func tokenDetailsActivityDidScroll(to pageNum: Int) {
        analyticsManager.log(event: .tokenDetailsActivityScroll(pageNum: pageNum))
    }
}
