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
    var prices: [Price] { PricesManager.bonfida.prices.value }
    
    var solWallet: Wallet? {data.first(where: {$0.symbol == "SOL"})}
    
    override func bind() {
        super.bind()
        PricesManager.bonfida.prices
            .subscribe(onNext: {prices in
                if self.items.count == 0 {return}
                var wallets = self.items
                for i in 0..<wallets.count {
                    if let price = prices.first(where: {$0.from == wallets[i].symbol}) {
                        wallets[i].price = price
                    }
                }
                self.items = wallets
                self.state.accept(.loaded(wallets))
            })
            .disposed(by: disposeBag)
        
        SolanaSDK.Socket.shared.observe(method: "accountNotification", decodedTo: SolanaSDK.Notification.Account.self)
            .subscribe(onNext: {notification in
                
            })
            .disposed(by: disposeBag)
    }
    
    override var request: Single<[Wallet]> {
        guard let account = SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString else {
            return .error(SolanaSDK.Error.publicKeyNotFound)
        }
        return SolanaSDK.shared.getBalance(account: account)
            .flatMap {balance in
                SolanaSDK.shared.getProgramAccounts(in: SolanaSDK.network)
                    .map {$0.map {Wallet(programAccount: $0)}}
                    .map {wallets in
                        var wallets = wallets
                        for i in 0..<wallets.count {
                            if let price = self.prices.first(where: {$0.from == wallets[i].symbol}) {
                                wallets[i].price = price
                            }
                        }
                        
                        let solWallet = Wallet(
                            id: SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString ?? "Solana",
                            name: "Solana",
                            mintAddress: "",
                            pubkey: SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString,
                            symbol: "SOL",
                            icon: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/solana/info/logo.png",
                            amount: Double(balance) * 0.000000001,
                            price: self.prices.first(where: {$0.from == "SOL"}),
                            decimals: 9
                        )
                        wallets.insert(solWallet, at: 0)
                        return wallets
                    }
            }
    }
    
    func updateAmountChange(_ change: Double, forWallet pubkey: String) {
        var items = self.items
        if let index = items.firstIndex(where: {$0.pubkey == pubkey}) {
            items[index].amount = items[index].amount + change
        } else {
            return
        }
        self.items = items
        self.state.accept(.loaded(items))
    }
}
