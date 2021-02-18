//
//  WalletTransactionsVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation
import RxSwift

class WalletTransactionsVM: ListViewModel<Transaction> {
    
    let wallet: Wallet
    var before: String?
    let solanaSDK: SolanaSDK
    let walletsVM: WalletsVM
    
    init(solanaSDK: SolanaSDK, walletsVM: WalletsVM, wallet: Wallet) {
        self.wallet = wallet
        self.solanaSDK = solanaSDK
        self.walletsVM = walletsVM
        super.init()
    }
    
    override var request: Single<[Transaction]> {
        guard let pubkey = wallet.pubkey else {
            return .error(SolanaSDK.Error.notFound)
        }
        return solanaSDK.getConfirmedSignaturesForAddress2(account: pubkey, configs: SolanaSDK.RequestConfiguration(limit: limit, before: before)
        )
        .do(onSuccess: {[weak self] activities in
            self?.before = activities.last?.signature
            guard let self = self else {return}
            let signatures = activities.map {$0.signature}
            signatures.forEach { signature in
                self.solanaSDK.getConfirmedTransaction(transactionSignature: signature)
                    .subscribe(onSuccess: {[weak self] transaction in
                        guard let self = self else {return}
                        self.updateItem(where: {$0.signature == signature}, transform: {
                            var newItem = $0
                            if let myAccountPubkey = self.solanaSDK.accountStorage.account?.publicKey
                            {
                                newItem.confirm(by: transaction, walletsVM: self.walletsVM, myAccountPubkey: myAccountPubkey)
                            }
                            return newItem
                        })
                        if let slot = transaction.slot {
                            self.solanaSDK.getBlockTime(block: slot)
                                .subscribe(onSuccess: {[weak self] timestamp in
                                    guard let self = self else {return}
                                    self.updateItem(where: {$0.signature == signature}, transform: {
                                        var transaction = $0
                                        transaction.timestamp = timestamp
                                        return transaction
                                    })
                                }, onError: {error in
                                    // TODO: Handle error
                                })
                                .disposed(by: self.disposeBag)
                        }
                        
                    }, onError: {error in
                        // TODO: Handle error
                    })
                    .disposed(by: self.disposeBag)
            }
            
        })
        .map {
            $0.compactMap {
                Transaction(
                    signatureInfo: $0,
                    symbol: self.wallet.symbol,
                    status: .confirmed
                )
            }
        }
    }
}
