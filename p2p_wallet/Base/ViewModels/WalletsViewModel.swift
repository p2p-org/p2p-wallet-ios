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
    private let transactionManager: TransactionsManager?
    private let pricesRepository: PricesRepository
    
    private var defaultsDisposables = [DefaultsDisposable]()
    private var disposeBag = DisposeBag()
    
    // MARK: - Getters
    var solWallet: Wallet? {data.first(where: {$0.symbol == "SOL"})}
    
    // MARK: - Subjects
    let isHiddenWalletsShown = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initializer
    init(
        solanaSDK: SolanaSDK,
        socket: SolanaSDK.Socket,
        transactionManager: TransactionsManager? = nil,
        pricesRepository: PricesRepository
    ) {
        self.solanaSDK = solanaSDK
        self.socket = socket
        self.transactionManager = transactionManager
        self.pricesRepository = pricesRepository
        super.init()
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
        
        // observe SOL balance
        socket.observeAccountNotification()
            .subscribe(onNext: {[weak self] notification in
                self?.updateItem(where: {$0.symbol == "SOL"}) { wallet in
                    var wallet = wallet
                    wallet.lamports = notification.value.lamports
                    return wallet
                }
            })
            .disposed(by: disposeBag)
        
        // observe hideZeroBalances settings
        defaultsDisposables.append(Defaults.observe(\.hideZeroBalances) { [weak self] _ in
            self?.updateWalletsVisibility()
        })
        
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
                self.solanaSDK.getTokensInfo()
                    .map {$0.map {Wallet(programAccount: $0)}}
                    .map {wallets in
                        var wallets = wallets
                        for i in 0..<wallets.count {
                            // update prices
                            if let price = PricesManager.shared.currentPrice(for: wallets[i].symbol)
                            {
                                wallets[i].price = price
                            }
                            // update visibility
                            wallets[i].updateVisibility()
                        }
                        
                        let solWallet = Wallet.createSOLWallet(
                            pubkey: self.solanaSDK.accountStorage.account?.publicKey.base58EncodedString,
                            lamports: balance,
                            price: PricesManager.shared.solPrice
                        )
                        wallets.insert(solWallet, at: 0)
                        return wallets
                    }
            }
    }
    
    override func join(_ newItems: [Wallet]) -> [Wallet] {
        var wallets = super.join(newItems)
        let solWallet = wallets.removeFirst()
        wallets = wallets
            .sorted(by: { lhs, rhs -> Bool in
                if lhs.isLiquidity != rhs.isLiquidity {
                    return !lhs.isLiquidity
                }
                if lhs.amountInUSD != rhs.amountInUSD {
                    return lhs.amountInUSD > rhs.amountInUSD
                }
                if lhs.amount != rhs.amount {
                    return lhs.amount.orZero > rhs.amount.orZero
                }
                if lhs.symbol != rhs.symbol {
                    return lhs.symbol < rhs.symbol
                }
                return lhs.mintAddress < rhs.mintAddress
            })
        return [solWallet] + wallets
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
    private func updatePrices() {
        guard currentState == .loaded else {return}
        var wallets = self.data
        for i in 0..<wallets.count {
            if let price = pricesRepository.currentPrice(for: wallets[i].symbol) {
                wallets[i].price = price
            }
        }
        overrideData(by: wallets)
    }
    
    private func updateWalletsVisibility() {
        guard currentState == .loaded else {return}
        var wallets = data
        for index in 0..<wallets.count where wallets[index].amount == 0 && wallets[index].symbol != "SOL"
        {
            var wallet = wallets[index]
            wallet.updateVisibility()
            wallets[index] = wallet
        }
        
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
