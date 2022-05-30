//
//  AccountNotificationsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/07/2021.
//

import Foundation
import RxSwift
import SolanaSwift

protocol SocketType {
    var isConnected: Bool { get }
    func subscribeAccountNotification(account: String, isNative: Bool)
    func observeAllAccountsNotifications() -> Observable<(pubkey: String, lamports: SolanaSDK.Lamports)>
}

extension Socket: SocketType {
    func subscribeAccountNotification(account _: String, isNative _: Bool) {
        fatalError("Method is not implemented")
    }

    func observeAllAccountsNotifications() -> Observable<(pubkey: String, lamports: SolanaSDK.Lamports)> {
        fatalError("Method is not implemented")

        // TODO: Fix
        // observeAccountNotifications()
    }
}
