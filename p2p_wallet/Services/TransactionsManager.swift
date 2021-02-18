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
    
    let disposeBag = DisposeBag()
    let socket: SolanaSDK.Socket
    
    init(socket: SolanaSDK.Socket) {
        self.socket = socket
    }
    
    func process(_ transaction: Transaction) {
        guard transaction.status != .confirmed, let signature = transaction.signature else {return}
        transactions.insert(transaction, where: {$0.signature == signature}, shouldUpdate: true)
        socket.observeSignatureNotification(signature: signature)
            .subscribe(onCompleted: {
                var transaction = transaction
                transaction.status = .confirmed
                transaction.newWallet?.isProcessing = false
                self.transactions.insert(transaction, where: {$0.signature == transaction.signature}, shouldUpdate: true)
            })
            .disposed(by: disposeBag)
    }
}
