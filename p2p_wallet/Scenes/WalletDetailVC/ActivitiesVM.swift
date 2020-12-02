//
//  ActivitiesVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2020.
//

import Foundation
import RxSwift

class ActivitiesVM: ListViewModel<Activity> {
    
    let wallet: Wallet
    
    init(wallet: Wallet) {
        self.wallet = wallet
        super.init()
    }
    
    override var request: Single<[Activity]> {
        guard let pubkey = wallet.pubkey else {
            return .error(SolanaSDK.Error.accountNotFound)
        }
        return SolanaSDK.shared.getConfirmedSignaturesForAddress2(account: pubkey, configs: SolanaSDK.RequestConfiguration(limit: 10)
        )
        .do(onSuccess: {[weak self] activities in
            guard let self = self else {return}
            let signatures = activities.map {$0.signature}
            signatures.forEach { signature in
                SolanaSDK.shared.getConfirmedTransaction(transactionSignature: signature)
                    .subscribe(onSuccess: {[weak self] transaction in
                        guard let self = self else {return}
                        self.updateItem(where: {$0.info?.signature == signature}, transform: {
                            var newItem = $0
                            newItem.withConfirmedTransaction(transaction)
                            return newItem
                        })
                        if let slot = transaction.slot {
                            SolanaSDK.shared.getBlockTime(block: slot)
                                .subscribe(onSuccess: {[weak self] timestamp in
                                    guard let self = self else {return}
                                    self.updateItem(where: {$0.info?.signature == signature}, transform: {
                                        var activity = $0
                                        activity.timestamp = timestamp
                                        return activity
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
            $0.compactMap {Activity(id: $0.signature, type: nil, amount: nil, tokens: nil, symbol: self.wallet.symbol, timestamp: nil, info: $0)}
        }
    }
}
