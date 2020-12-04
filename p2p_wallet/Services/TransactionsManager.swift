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
    public let transactions = BehaviorRelay<[Transaction]>(value: [])
    
    static let shared = TransactionsManager()
    let disposeBag = DisposeBag()
    private init() {}
    
    func process(_ transaction: Transaction) {
        guard transaction.status != .confirmed else {return}
        transactions.insert(transaction, where: {$0.signature == transaction.signature}, shouldUpdate: true)
        let socket = SolanaSDK.Socket.shared
        socket.observeSignatureNotification(signature: transaction.signature)
            .subscribe(onCompleted: {
                var transaction = transaction
                transaction.status = .confirmed
                self.transactions.insert(transaction, where: {$0.signature == transaction.signature}, shouldUpdate: true)
            })
            .disposed(by: disposeBag)
    }
}
