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
    func observeAllAccountsNotifications() -> Observable<(pubkey: String, lamports: Lamports)>
}

extension SolanaSDK.Socket: SocketType {
    func observeAllAccountsNotifications() -> Observable<(pubkey: String, lamports: Lamports)> {
        observeAccountNotifications()
    }
}
