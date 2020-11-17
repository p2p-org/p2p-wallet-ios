//
//  WalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift

class WalletVM: ListViewModel<Wallet> {
    static var ofCurrentUser = WalletVM()
    var prices: [Price] { PricesManager.bonfida.prices.value }
    
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
                            name: "Solana",
                            mintAddress: "",
                            symbol: "SOL",
                            icon: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/solana/info/logo.png",
                            amount: balance,
                            price: Price(from: "SOL", to: "USDT", value: Double(balance) * 0.000000001, change24h: nil)
                        )
                        wallets.insert(solWallet, at: 0)
                        return wallets
                    }
            }
        
        
    }
}
