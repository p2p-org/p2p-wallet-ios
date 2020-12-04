//
//  TransactionsManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/12/2020.
//

import Foundation
import RxSwift
import RxCocoa

struct TransactionsManager {
    public let processingTransactions = BehaviorRelay<[Transaction]>(value: [])
    
    static let shared = TransactionsManager()
    let disposeBag = DisposeBag()
    private init() {}
    
    func process(_ transaction: Transaction) {
        processingTransactions.insert(transaction, where: {$0.signature == transaction.signature}, shouldUpdate: true)
        let socket = SolanaSDK.Socket.shared
        socket.observeSignatureNotification(signature: transaction.signature)
            .subscribe(onCompleted: {
                self.processingTransactions.removeAll(where: {$0.signature == transaction.signature})
            })
            .disposed(by: disposeBag)
    }
}
