//
//  WalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import RxSwift

class WalletVM: ListViewModel<Wallet> {
    let solBalanceVM = SolBalanceVM.ofCurrentUser
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
    
    override func refresh() {
        super.reload()
        solBalanceVM.reload()
    }
    
    override var request: Single<[Wallet]> {
        SolanaSDK.shared.getProgramAccounts(in: SolanaSDK.network)
            .map {$0.map {Wallet(programAccount: $0)}}
            .map {wallets in
                var wallets = wallets
                for i in 0..<wallets.count {
                    if let price = self.prices.first(where: {$0.from == wallets[i].symbol}) {
                        wallets[i].price = price
                    }
                }
                return wallets
            }
    }
    
    override var dataDidChange: Observable<Void> {
        Observable<Void>.merge(solBalanceVM.state.map {_ in ()}, state.map {_ in ()})
    }
}
