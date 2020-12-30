//
//  WalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift

class WalletsVM: ListViewModel<Wallet> {
    override var isPaginationEnabled: Bool {false}
    
    static var ofCurrentUser = WalletsVM()
    
    var solWallet: Wallet? {data.first(where: {$0.symbol == "SOL"})}
    
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
        
        SolanaSDK.Socket.shared.observeAccountNotification()
            .subscribe(onNext: {notification in
                self.updateItem(where: {$0.symbol == "SOL"}) { wallet in
                    var wallet = wallet
                    wallet.lamports = notification.value.lamports
                    return wallet
                }
            })
            .disposed(by: disposeBag)
    }
    
    override var request: Single<[Wallet]> {
        guard let account = SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString else {
            return .error(SolanaSDK.Error.publicKeyNotFound)
        }
        return SolanaSDK.shared.getBalance(account: account)
            .flatMap {balance in
                SolanaSDK.shared.getProgramAccounts(in: Defaults.network.cluster)
                    .map {$0.map {Wallet(programAccount: $0)}}
                    .map {wallets in
                        var wallets = wallets
                        for i in 0..<wallets.count {
                            if let price = PricesManager.shared.currentPrice(for: wallets[i].symbol)
                            {
                                wallets[i].price = price
                            }
                        }
                        
                        let solWallet = Wallet(
                            id: SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString ?? "Solana",
                            name: Defaults.walletName["SOL"] ?? "Solana",
                            mintAddress: "",
                            pubkey: SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString,
                            symbol: "SOL",
                            lamports: balance,
                            price: PricesManager.shared.solPrice,
                            decimals: 9,
                            indicatorColor: .black
                        )
                        wallets.insert(solWallet, at: 0)
                        return wallets
                    }
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
            .sorted(by: {$0.amountInUSD > $1.amountInUSD})
        return [solWallet] + wallets
    }
}
