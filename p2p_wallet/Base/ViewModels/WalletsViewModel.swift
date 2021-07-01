//
//  WalletsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift
import RxCocoa
import BECollectionView
import RxAppState

class WalletsViewModel: BEListViewModel<Wallet> {
    // MARK: - Properties
    private let solanaSDK: SolanaSDK
    private let socket: SolanaSDK.Socket
    private let processingTransactionRepository: ProcessingTransactionsRepository
    private let pricesRepository: PricesRepository
    
    private var defaultsDisposables = [DefaultsDisposable]()
    private var disposeBag = DisposeBag()
    
    // MARK: - Getters
    var solWallet: Wallet? {data.first(where: {$0.token.symbol == "SOL"})}
    
    // MARK: - Subjects
    let isHiddenWalletsShown = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initializer
    init(
        solanaSDK: SolanaSDK,
        socket: SolanaSDK.Socket,
        processingTransactionRepository: ProcessingTransactionsRepository,
        pricesRepository: PricesRepository
    ) {
        self.solanaSDK = solanaSDK
        self.socket = socket
        self.processingTransactionRepository = processingTransactionRepository
        self.pricesRepository = pricesRepository
        super.init()
        
        self.customSorter = Wallet.defaultSorter
        bind()
    }
    
    // MARK: - Binding
    override func bind() {
        super.bind()
        
        // observe prices
        pricesRepository.pricesObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.updatePrices()
            })
            .disposed(by: disposeBag)
        
        // observe tokens' balance
        socket.observeAccountNotifications()
            .subscribe(onNext: {[weak self] notification in
                self?.updateItem(where: {$0.pubkey == notification.pubkey}, transform: { wallet in
                    var wallet = wallet
                    wallet.lamports = notification.lamports
                    return wallet
                })
            })
            .disposed(by: disposeBag)
        
        // observe hideZeroBalances settings
        defaultsDisposables.append(Defaults.observe(\.hideZeroBalances) { [weak self] _ in
            self?.updateWalletsVisibility()
        })
        
        // observe account notification
        dataObservable
            .map {[weak self] _ in self?.getWallets() ?? []}
            .subscribe(onNext: {[weak self] wallets in
                for wallet in wallets where wallet.pubkey != nil {
                    self?.socket.subscribeAccountNotification(account: wallet.pubkey!)
                }
            })
            .disposed(by: disposeBag)
        
        // observe app state
        UIApplication.shared.rx
            .applicationDidBecomeActive
            .subscribe(onNext: {[weak self] _ in
                self?.appDidBecomeActive()
            })
            .disposed(by: disposeBag)
        
        UIApplication.shared.rx
            .applicationDidEnterBackground
            .subscribe(onNext: {[weak self] _ in
                self?.appDidEnterBackground()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Methods
    override func createRequest() -> Single<[Wallet]> {
        solanaSDK.getBalance()
            .flatMap {balance in
                self.solanaSDK.getTokenWallets()
                    // update visibility
                    .map {[weak self] wallets in
                        self?.mapVisibility(wallets: wallets) ?? []
                    }
                    // add sol wallet on top
                    .map {[weak self] wallets in
                        var wallets = wallets
                        let solWallet = Wallet.nativeSolana(
                            pubkey: self?.solanaSDK.accountStorage.account?.publicKey.base58EncodedString,
                            lamport: balance
                        )
                        wallets.insert(solWallet, at: 0)
                        return wallets
                    }
            }
    }
    
    override func map(newData: [Wallet]) -> [Wallet] {
        mapPrices(wallets: newData).sorted(by: Wallet.defaultSorter)
    }
    
    override func reload() {
        // disable refreshing when there is a transaction in progress
        if processingTransactionRepository.areSomeTransactionsInProgress()
        {
            return
        }
        
        if pricesRepository.getCurrentPrices().isEmpty {
            pricesRepository.fetchAllTokensPrice()
        }
        
        super.reload()
    }
    
    override var dataDidChange: Observable<Void> {
        Observable.combineLatest(
            super.dataDidChange,
            isHiddenWalletsShown.distinctUntilChanged()
        )
            .map {_ in ()}
    }
    
    // MARK: - getters
    func hiddenWallets() -> [Wallet] {
        data.filter {$0.isHidden}
    }
    
    func shownWallets() -> [Wallet] {
        data.filter { !hiddenWallets().contains($0) }
    }
    
    // MARK: - Actions
    @objc func toggleIsHiddenWalletShown() {
        isHiddenWalletsShown.accept(!isHiddenWalletsShown.value)
    }
    
    func toggleWalletVisibility(_ wallet: Wallet) {
        if wallet.isHidden {
            unhideWallet(wallet)
        } else {
            hideWallet(wallet)
        }
    }
    
    func updateWallet(_ wallet: Wallet, withName name: String) {
        Defaults.walletName[wallet.pubkey!] = name
        updateItem(where: {wallet.pubkey == $0.pubkey}, transform: {
            var newItem = $0
            newItem.setName(name)
            return newItem
        })
    }
    
    // MARK: - Mappers
    private func mapPrices(wallets: [Wallet]) -> [Wallet] {
        var wallets = wallets
        for i in 0..<wallets.count {
            if let price = pricesRepository.currentPrice(for: wallets[i].token.symbol)
            {
                wallets[i].price = price
            } else {
                wallets[i].price = nil
            }
        }
        return wallets
    }
    
    private func mapVisibility(wallets: [Wallet]) -> [Wallet] {
        var wallets = wallets
        for i in 0..<wallets.count {
            // update visibility
            wallets[i].updateVisibility()
        }
        return wallets
    }
    
    // MARK: - Helpers
    private func updatePrices() {
        guard currentState == .loaded else {return}
        let wallets = mapPrices(wallets: data)
        overrideData(by: wallets)
    }
    
    private func updateWalletsVisibility() {
        guard currentState == .loaded else {return}
        let wallets = mapVisibility(wallets: data)
        overrideData(by: wallets)
    }
    
    private func hideWallet(_ wallet: Wallet) {
        Defaults.unhiddenWalletPubkey.removeAll(where: {$0 == wallet.pubkey})
        Defaults.hiddenWalletPubkey.appendIfNotExist(wallet.pubkey)
        self.updateItem(where: {
            $0.pubkey == wallet.pubkey
        }) { wallet -> Wallet? in
            var wallet = wallet
            wallet.updateVisibility()
            return wallet
        }
    }
    
    private func unhideWallet(_ wallet: Wallet) {
        Defaults.unhiddenWalletPubkey.appendIfNotExist(wallet.pubkey)
        Defaults.hiddenWalletPubkey.removeAll(where: {$0 == wallet.pubkey})
        self.updateItem(where: {
            $0.pubkey == wallet.pubkey
        }) { wallet -> Wallet? in
            var wallet = wallet
            wallet.updateVisibility()
            return wallet
        }
    }
    
    // MARK: - App state
    private(set) var shouldUpdateBalance = false
    private func appDidBecomeActive() {
        // update balance
        if shouldUpdateBalance {
            reload()
            shouldUpdateBalance = false
        }
    }
    
    private func appDidEnterBackground() {
        shouldUpdateBalance = true
    }
}

fileprivate extension Wallet {
    static var defaultSorter: (Wallet, Wallet) -> Bool {
        { lhs, rhs in
            // Solana
            if lhs.token.isNative != rhs.token.isNative {
                return lhs.token.isNative
            }
            
            if lhs.token.symbol == "SOL" || rhs.token.symbol == "SOL" {
                return lhs.token.symbol == "SOL"
            }
            
            if lhs.token.isLiquidity != rhs.token.isLiquidity {
                return !lhs.token.isLiquidity
            }
            
            if lhs.amountInCurrentFiat != rhs.amountInCurrentFiat {
                return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
            }
            
            if lhs.amount != rhs.amount {
                return lhs.amount.orZero > rhs.amount.orZero
            }
            
            if lhs.token.symbol != rhs.token.symbol {
                return lhs.token.symbol < rhs.token.symbol
            }
            
            return lhs.name < rhs.name
        }
    }
}
