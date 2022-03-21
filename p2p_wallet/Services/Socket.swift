//
//  AccountNotificationsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/07/2021.
//

import Foundation
import RxSwift

protocol SocketType {
    var isConnected: Bool { get }
    func subscribeAccountNotification(account: String, isNative: Bool)
    func observeAllAccountsNotifications() -> Observable<(pubkey: String, lamports: SolanaSDK.Lamports)>
    func observeAccountNotifications(account: String) -> Observable<SolanaSDK.Lamports>
}

extension SolanaSDK.Socket: SocketType {
    func observeAccountNotifications(account: String) -> Observable<SolanaSDK.Lamports> {
        observeAccountNotifications().filter { $0.pubkey == account }
            .map { $0.lamports }.distinctUntilChanged()
    }

    func observeAllAccountsNotifications() -> Observable<(pubkey: String, lamports: SolanaSDK.Lamports)> {
        observeAccountNotifications()
    }
}
