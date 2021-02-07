//
//  _AddNewWalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/02/2021.
//

import Foundation
import LazySubject

class _AddNewWalletVM: ListViewModel<Wallet> {
    let feeSubject = LazySubject(
        value: Double(0),
        request: SolanaSDK.shared.getCreatingTokenAccountFee()
            .map {
                let decimals = WalletsVM.ofCurrentUser.items.first(where: {$0.symbol == "SOL"})?.decimals ?? 9
                return Double($0) * pow(Double(10), -Double(decimals))
            }
    )
    
    override func reload() {
        // get static data
        var wallets = SolanaSDK.Token.getSupportedTokens(network: Defaults.network)?.compactMap {$0 != nil ? Wallet(programAccount: $0!) : nil} ?? []
        
        for i in 0..<wallets.count {
            if let price = PricesManager.shared.currentPrice(for: wallets[i].symbol)
            {
                wallets[i].price = price
            }
        }
        
        data = wallets
            .filter { newWallet in
                !WalletsVM.ofCurrentUser.data.contains(where: {$0.mintAddress == newWallet.mintAddress})
            }
        state.accept(.loaded(data))
        
        // fee
        feeSubject.reload()
    }
    override func fetchNext() { /* do nothing */ }
    
    override func offlineSearchPredicate(item: Wallet, lowercasedQuery query: String) -> Bool {
        item.name.lowercased().contains(query) ||
        item.symbol.lowercased().contains(query)
    }
}
