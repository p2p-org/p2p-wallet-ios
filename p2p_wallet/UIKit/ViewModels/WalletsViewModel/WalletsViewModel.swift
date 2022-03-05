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
import Resolver

class WalletsViewModel: BEListViewModel<Wallet> {
    // MARK: - Dependencies
    @Injected private var solanaSDK: SolanaSDK
    @Injected private var pricesService: PricesServiceType
    @Injected private var accountNotificationsRepository: AccountNotificationsRepository
    @WeakLazyInjected private var transactionHandler: TransactionHandlerType?
    
    // MARK: - Properties
    private var defaultsDisposables = [DefaultsDisposable]()
    private var disposeBag = DisposeBag()
    let notificationsSubject = BehaviorRelay<WLNotification?>(value: nil)
    var notifications = [WLNotification]()
    private var timer: Timer?
    
    // MARK: - Getters
    var nativeWallet: Wallet? {data.first(where: {$0.isNativeSOL})}
    
    // MARK: - Subjects
    let isHiddenWalletsShown = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initializer
    init() {
        super.init()
        bind()
        startObserving()
    }
    
    deinit {
        stopObserving()
    }
    
    // MARK: - Binding
    override func bind() {
        super.bind()
        
        // observe prices
        pricesService.currentPricesDriver
            .drive(onNext: { [weak self] _ in
                self?.updatePrices()
            })
            .disposed(by: disposeBag)
        
        // observe tokens' balance
        accountNotificationsRepository.observeAllAccountsNotifications()
            .subscribe(onNext: {[weak self] notification in
                self?.handleAccountNotification(notification)
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
                    self?.accountNotificationsRepository.subscribeAccountNotification(account: wallet.pubkey!, isNative: wallet.isNativeSOL)
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
    
    // MARK: - Observing
    func startObserving() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: {[weak self] _ in
            self?.getNewWallet()
        })
    }
    
    func stopObserving() {
        timer?.invalidate()
    }
    
    // MARK: - Methods
    override func createRequest() -> Single<[Wallet]> {
        Single.zip(
            solanaSDK.getBalance(),
            solanaSDK.getTokenWallets()
        )
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .map {[weak self] balance, wallets in
                guard let self = self else {return []}
                var wallets = wallets
                
                // add sol wallet on top
                let solWallet = Wallet.nativeSolana(
                    pubkey: self.solanaSDK.accountStorage.account?.publicKey.base58EncodedString,
                    lamport: balance
                )
                wallets.insert(solWallet, at: 0)
                
                // update visibility
                wallets = self.mapVisibility(wallets: wallets)
                
                // map prices
                wallets = self.mapPrices(wallets: wallets)
                
                // sort
                wallets.sort(by: Wallet.defaultSorter)
                
                return wallets
            }
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { [weak self] wallets in
                guard let self = self else {return}
                let newTokens = wallets.map {$0.token.symbol}
                    .filter {!self.pricesService.getWatchList().contains($0)}
                self.pricesService.addToWatchList(newTokens)
                self.pricesService.fetchPrices(tokens: newTokens)
            })
    }
    
    override func reload() {
        // disable refreshing when there is a transaction in progress
        if transactionHandler?.areSomeTransactionsInProgress() == true
        {
            return
        }
        
        super.reload()
    }
    
    @objc private func getNewWallet() {
        solanaSDK.getTokenWallets(log: false)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map { [weak self] newData -> [Wallet] in
                guard let self = self else {return []}
                var data = self.data
                var newWallets = newData
                    .filter {wl in !data.contains(where: {$0.pubkey == wl.pubkey})}
                    .filter {$0.lamports != 0}
                newWallets = self.mapPrices(wallets: newWallets)
                newWallets = self.mapVisibility(wallets: newWallets)
                data.append(contentsOf: newWallets)
                data.sort(by: Wallet.defaultSorter)
                return data
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: {[weak self] data in
                self?.overrideData(by: data)
            })
            .disposed(by: disposeBag)
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
            wallets[i].price = pricesService.currentPrice(for: wallets[i].token.symbol)
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
        updateVisibility(for: wallet)
    }
    
    private func unhideWallet(_ wallet: Wallet) {
        Defaults.unhiddenWalletPubkey.appendIfNotExist(wallet.pubkey)
        Defaults.hiddenWalletPubkey.removeAll(where: {$0 == wallet.pubkey})
        updateVisibility(for: wallet)
    }
    
    private func updateVisibility(for wallet: Wallet) {
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
            getNewWallet()
            shouldUpdateBalance = false
        }
    }
    
    private func appDidEnterBackground() {
        shouldUpdateBalance = true
    }
    
    // MARK: - Account notifications
    private func handleAccountNotification(_ notification: (pubkey: String, lamports: SolanaSDK.Lamports))
    {
        // notify changes
        let oldLamportsValue = data.first(where: {$0.pubkey == notification.pubkey})?.lamports
        let newLamportsValue = notification.lamports
        
        if let oldLamportsValue = oldLamportsValue {
            var wlNoti: WLNotification?
            if oldLamportsValue > newLamportsValue {
                // sent
                wlNoti = .sent(account: notification.pubkey, lamports: oldLamportsValue - newLamportsValue)
            } else if oldLamportsValue < newLamportsValue {
                // received
                wlNoti = .received(account: notification.pubkey, lamports: newLamportsValue - oldLamportsValue)
            }
            if let wlNoti = wlNoti {
                notificationsSubject.accept(wlNoti)
                notifications.append(wlNoti)
            }
        }
        
        // update
        updateItem(where: {$0.pubkey == notification.pubkey}, transform: { wallet in
            var wallet = wallet
            wallet.lamports = notification.lamports
            return wallet
        })
    }
}

fileprivate extension Wallet {
    static var defaultSorter: (Wallet, Wallet) -> Bool {
        { lhs, rhs in
            // Solana
            if lhs.isNativeSOL != rhs.isNativeSOL {
                return lhs.isNativeSOL
            }
            
            if lhs.token.isLiquidity != rhs.token.isLiquidity {
                return !lhs.token.isLiquidity
            }
            
            if lhs.amountInCurrentFiat != rhs.amountInCurrentFiat {
                return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
            }
            
            if lhs.token.symbol.isEmpty != rhs.token.symbol.isEmpty {
                return !lhs.token.symbol.isEmpty
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
