//
//  TransactionHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation
import RxSwift

protocol TransactionHandler {
    func observeTransactionCompletion(signature: String) -> Completable
}

extension SolanaSDK.Socket: TransactionHandler {
    func observeTransactionCompletion(signature: String) -> Completable {
        observeSignatureNotification(signature: signature)
    }
}
