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
                SolanaSDK.shared.getProgramAccounts(in: SolanaSDK.network)
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
                            name: "Solana",
                            mintAddress: "",
                            pubkey: SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString,
                            symbol: "SOL",
                            icon: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/solana/info/logo.png",
                            lamports: balance,
                            price: PricesManager.shared.solPrice,
                            decimals: 9
                        )
                        wallets.insert(solWallet, at: 0)
                        return wallets
                    }
            }
    }
}
