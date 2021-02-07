//
//  _AddNewWalletVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/02/2021.
//

import Foundation
import RxSwift
import LazySubject
import Action

class _AddNewWalletVM: ListViewModel<Wallet> {
    let feeSubject = LazySubject(
        value: Double(0),
        request: SolanaSDK.shared.getCreatingTokenAccountFee()
            .map {
                let decimals = WalletsVM.ofCurrentUser.items.first(where: {$0.symbol == "SOL"})?.decimals ?? 9
                return Double($0) * pow(Double(10), -Double(decimals))
            }
    )
    
    let navigatorSubject = PublishSubject<Navigator>()
    let clearSearchBarSubject = PublishSubject<Void>()
    
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
    
    func tokenDidSelect(_ token: Wallet) {
        updateItem(where: {token.mintAddress == $0.mintAddress}, transform: {
            var wallet = $0
            wallet.isExpanded = !(wallet.isExpanded ?? false)
            return wallet
        })
    }
    
    func addNewToken(newWallet: Wallet) -> CocoaAction {
        CocoaAction {
            // catching error
            if self.feeSubject.value > (WalletsVM.ofCurrentUser.solWallet?.amount ?? 0)
            {
                self.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                    var wallet = $0
                    wallet.isBeingCreated = nil
                    wallet.creatingError = L10n.insufficientFunds
                    return wallet
                })
                return .just(())
            }
            
            // remove existing error
            self.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                var wallet = $0
                wallet.isBeingCreated = true
                wallet.creatingError = nil
                return wallet
            })
            
            // request
            return SolanaSDK.shared.createTokenAccount(mintAddress: newWallet.mintAddress)
//            return Single<(String, String)>.just(("", "")).delay(.seconds(5), scheduler: MainScheduler.instance)
//                .map {_ -> (String, String) in
//                    throw SolanaSDK.Error.other("example")
//                }
                .do(
                    afterSuccess: { (signature, newPubkey) in
                        // remove suggestion from the list
                        self.removeItem(where: {$0.mintAddress == newWallet.mintAddress})
                        
                        // cancel search if search result is empty
                        if self.searchResult?.isEmpty == true
                        {
                            self.clearSearchBarSubject.onNext(())
                        }
                        
                        // process transaction
                        var newWallet = newWallet
                        newWallet.pubkey = newPubkey
                        newWallet.isProcessing = true
                        let transaction = Transaction(
                            signatureInfo: .init(signature: signature),
                            type: .createAccount,
                            amount: -(self.feeSubject.value ?? 0),
                            symbol: "SOL",
                            status: .processing,
                            newWallet: newWallet
                        )
                        TransactionsManager.shared.process(transaction)
                        
                        // present wallet
                        self.navigatorSubject.onNext(.present(WalletDetailVC(wallet: newWallet)))
                    },
                    afterError: { (error) in
                        self.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                            var wallet = $0
                            wallet.isBeingCreated = nil
                            wallet.creatingError = error.localizedDescription
                            return wallet
                        })
                    }
                )
                .map {_ in ()}
                .asObservable()
        }
    }
}
