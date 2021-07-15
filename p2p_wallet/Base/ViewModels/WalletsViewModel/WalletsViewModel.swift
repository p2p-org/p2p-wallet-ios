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
    // MARK: - Dependencies
    private let solanaSDK: SolanaSDK
    let accountNotificationsRepository: AccountNotificationsRepository
    weak var processingTransactionRepository: ProcessingTransactionsRepository?
    private let pricesRepository: PricesRepository
    
    // MARK: - Properties
    private var defaultsDisposables = [DefaultsDisposable]()
    private var disposeBag = DisposeBag()
    let notificationsSubject = BehaviorRelay<WLNotification?>(value: nil)
    var notifications = [WLNotification]()
    private var timer: Timer?
    
    // MARK: - Getters
    var solWallet: Wallet? {data.first(where: {$0.token.symbol == "SOL"})}
    
    // MARK: - Subjects
    let isHiddenWalletsShown = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initializer
    init(
        solanaSDK: SolanaSDK,
        accountNotificationsRepository: AccountNotificationsRepository,
        pricesRepository: PricesRepository
    ) {
        self.solanaSDK = solanaSDK
        self.accountNotificationsRepository = accountNotificationsRepository
        self.pricesRepository = pricesRepository
        super.init()
        
        self.customSorter = Wallet.defaultSorter
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
        pricesRepository.pricesObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.refreshUI()
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
            self?.refreshUI()
        })
        
        // observe account notification
        dataObservable
            .map {[weak self] _ in self?.getWallets() ?? []}
            .subscribe(onNext: {[weak self] wallets in
                for wallet in wallets where wallet.pubkey != nil {
                    self?.accountNotificationsRepository.subscribeAccountNotification(account: wallet.pubkey!)
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
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(getNewWallet), userInfo: nil, repeats: true)
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
        
            .map {[weak self] balance, wallets in
                guard let self = self else {return []}
                var wallets = wallets
                
                // add sol wallet on top
                let solWallet = Wallet.nativeSolana(
                    pubkey: self.solanaSDK.accountStorage.account?.publicKey.base58EncodedString,
                    lamport: balance
                )
                wallets.insert(solWallet, at: 0)
                
                return wallets
            }
    }
    
    override func map(newData: [Wallet]) -> [Wallet] {
        var wallets = newData
        // update visibility
        for i in 0..<wallets.count {
            // update visibility
            wallets[i].updateVisibility()
        }
        
        // map prices
        for i in 0..<wallets.count {
            if let price = pricesRepository.currentPrice(for: wallets[i].token.symbol)
            {
                wallets[i].price = price
            } else {
                wallets[i].price = nil
            }
        }
        
        return super.map(newData: wallets)
    }
    
    override func reload() {
        // disable refreshing when there is a transaction in progress
        if processingTransactionRepository?.areSomeTransactionsInProgress() == true
        {
            return
        }
        
        super.reload()
    }
    
    @objc private func getNewWallet() {
        solanaSDK.getTokenWallets()
            .subscribe(onSuccess: {[weak self] newData in
                guard let self = self else {return}
                var data = self.data
                let newWallets = newData
                    .filter {wl in !data.contains(where: {$0.pubkey == wl.pubkey})}
                    .filter {$0.lamports == 0}
                data.append(contentsOf: newWallets)
                self.overrideData(by: data)
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
    
    // MARK: - Helpers
    private func hideWallet(_ wallet: Wallet) {
        Defaults.unhiddenWalletPubkey.removeAll(where: {$0 == wallet.pubkey})
        Defaults.hiddenWalletPubkey.appendIfNotExist(wallet.pubkey)
        refreshUI()
    }
    
    private func unhideWallet(_ wallet: Wallet) {
        Defaults.unhiddenWalletPubkey.appendIfNotExist(wallet.pubkey)
        Defaults.hiddenWalletPubkey.removeAll(where: {$0 == wallet.pubkey})
        refreshUI()
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
