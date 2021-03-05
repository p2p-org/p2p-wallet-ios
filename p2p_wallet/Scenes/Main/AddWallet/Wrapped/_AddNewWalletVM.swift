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
    let solanaSDK: SolanaSDK
    let walletsVM: WalletsVM
    let transactionManager: TransactionsManager
    let scenesFactory: AddNewWalletScenesFactory
    lazy var feeSubject = LazySubject(
        value: Double(0),
        request: solanaSDK.getCreatingTokenAccountFee()
            .map {
                let decimals = self.walletsVM.items.solWallet?.decimals ?? 9
                return Double($0) * pow(Double(10), -Double(decimals))
            }
    )
    
    let navigatorSubject = PublishSubject<Navigation>()
    let clearSearchBarSubject = PublishSubject<Void>()
    
    init(solanaSDK: SolanaSDK, walletsVM: WalletsVM, transactionManager: TransactionsManager, scenesFactory: AddNewWalletScenesFactory) {
        self.solanaSDK = solanaSDK
        self.walletsVM = walletsVM
        self.transactionManager = transactionManager
        self.scenesFactory = scenesFactory
    }
    
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
                !walletsVM.data.contains(where: {$0.mintAddress == newWallet.mintAddress})
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
            if self.feeSubject.value > (self.walletsVM.solWallet?.amount ?? 0)
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
            self.solanaSDK.createTokenAccount(mintAddress: newWallet.mintAddress)
//            return Single<(String, String)>.just(("", "")).delay(.seconds(5), scheduler: MainScheduler.instance)
//                .map {_ -> (String, String) in
//                    throw SolanaSDK.Error.other("example")
//                }
                .subscribe(onSuccess: { (signature, newPubkey) in
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
                        self.transactionManager.process(transaction)
                    
                    // add to walletsVM
                    self.walletsVM.state.accept(.loaded(self.walletsVM.data + [newWallet]))
                        
                        // present wallet
                        let vc = self.scenesFactory.makeWalletDetailViewController(pubkey: newPubkey)
                        self.navigatorSubject.onNext(.present(vc))
                    },
                    onError: { (error) in
                        let description = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                        self.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                            var wallet = $0
                            wallet.isBeingCreated = nil
                            wallet.creatingError = description
                            return wallet
                        })
                    }
                )
                .disposed(by: self.disposeBag)
            return .just(())
        }
    }
}
