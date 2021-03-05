//
//  WalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift
import RxCocoa

class WalletsVM: ListViewModel<Wallet> {
    override var isPaginationEnabled: Bool {false}
    
    let isHiddenWalletsShown = BehaviorRelay<Bool>(value: Defaults.isHiddenWalletsShown)
    
    let solanaSDK: SolanaSDK
    let socket: SolanaSDK.Socket
    let transactionManager: TransactionsManager?
    private(set) var shouldUpdateBalance = false
    
    var solWallet: Wallet? {data.first(where: {$0.symbol == "SOL"})}
    var defaultsDisposables = [DefaultsDisposable]()
    
    init(solanaSDK: SolanaSDK, socket: SolanaSDK.Socket, transactionManager: TransactionsManager? = nil) {
        self.solanaSDK = solanaSDK
        self.socket = socket
        self.transactionManager = transactionManager
        super.init(prefetch: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func bind() {
        super.bind()
        PricesManager.shared.currentPrices
            .subscribe(onNext: {_ in
                if self.items.count == 0 {return}
                var wallets = self.items
                for i in 0..<wallets.count {
                    if let price = PricesManager.shared.currentPrice(for: wallets[i].symbol) {
                        wallets[i].price = price
                    }
                }
                self.items = wallets
                self.state.accept(.loaded(wallets))
            })
            .disposed(by: disposeBag)
        
        socket.observeAccountNotification()
            .subscribe(onNext: {notification in
                self.updateItem(where: {$0.symbol == "SOL"}) { wallet in
                    var wallet = wallet
                    wallet.lamports = notification.value.lamports
                    return wallet
                }
            })
            .disposed(by: disposeBag)
        
        transactionManager?.transactions
            .map {$0.filter {$0.type == .createAccount && $0.newWallet != nil}}
            .filter {$0.count > 0}
            .subscribe(onNext: { transactions in
                let newWallets = transactions.compactMap({$0.newWallet})
                var wallets = self.items
                for wallet in newWallets {
                    if !wallets.contains(where: {$0.pubkey == wallet.pubkey}) {
                        wallets.append(wallet)
                    } else {
                        self.updateItem(where: {$0.pubkey == wallet.pubkey}) { oldWallet in
                            var newWallet = oldWallet
                            newWallet.isProcessing = wallet.isProcessing
                            return newWallet
                        }
                    }
                }
                
                if wallets.count > 0 {
                    self.items = wallets
                    self.state.accept(.loaded(wallets))
                }
            })
            .disposed(by: disposeBag)
        
        defaultsDisposables.append(
            Defaults.observe(\.isHiddenWalletsShown, handler: { (update) in
                guard let newValue = update.newValue, self.isHiddenWalletsShown.value != newValue else {return}
                self.isHiddenWalletsShown.accept(newValue)
            })
        )
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override var request: Single<[Wallet]> {
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
                            if let pubkey = wallets[i].pubkey {
                                wallets[i].isHidden = Defaults.hiddenWalletPubkey.contains(pubkey)
                            }
                        }
                        
                        let solWallet = Wallet(
                            id: self.solanaSDK.accountStorage.account?.publicKey.base58EncodedString ?? "Solana",
                            name: Defaults.walletName["SOL"] ?? "Solana",
                            mintAddress: SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString,
                            pubkey: self.solanaSDK.accountStorage.account?.publicKey.base58EncodedString,
                            symbol: "SOL",
                            lamports: balance,
                            price: PricesManager.shared.solPrice,
                            decimals: 9,
                            indicatorColor: .black,
                            isLiquidity: false
                        )
                        wallets.insert(solWallet, at: 0)
                        return wallets
                    }
            }
    }
    override var dataDidChange: Observable<Void> {
        Observable.combineLatest(
            super.dataDidChange,
            isHiddenWalletsShown.distinctUntilChanged()
        )
            .map {_ in ()}
    }
    
    func hideWallet(_ wallet: Wallet) {
        Defaults.hiddenWalletPubkey.appendIfNotExist(wallet.pubkey)
        self.updateItem(where: {
            $0.pubkey == wallet.pubkey
        }) { wallet -> Wallet? in
            var wallet = wallet
            wallet.isHidden = true
            return wallet
        }
    }
    
    func unhideWallet(_ wallet: Wallet) {
        Defaults.hiddenWalletPubkey.removeAll(where: {$0 == wallet.pubkey})
        self.updateItem(where: {
            $0.pubkey == wallet.pubkey
        }) { wallet -> Wallet? in
            var wallet = wallet
            wallet.isHidden = false
            return wallet
        }
    }
    
    func updateWallet(_ wallet: Wallet, withName name: String) {
        Defaults.walletName[wallet.pubkey!] = name
        updateItem(where: {wallet.pubkey == $0.pubkey}, transform: {
            var newItem = $0
            newItem.name = name
            return newItem
        })
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
    
    @objc func appDidBecomeActive() {
        // update balance
        if shouldUpdateBalance {
            reload()
            shouldUpdateBalance = false
        }
    }
    
    @objc func appDidEnterBackground() {
        shouldUpdateBalance = true
    }
    
    @objc func toggleIsHiddenWalletShown() {
        Defaults.isHiddenWalletsShown.toggle()
    }
    
    func hiddenWallets() -> [Wallet] {
        items.filter {$0.isHidden}
    }
    
    func shownWallets() -> [Wallet] {
        items.filter { !hiddenWallets().contains($0) }
    }
}
