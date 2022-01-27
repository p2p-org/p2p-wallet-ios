//
//  AccountNotificationsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/07/2021.
//

import Foundation
import RxSwift

protocol AccountNotificationsRepository {
    func subscribeAccountNotification(account: String, isNative: Bool)
    func observeAllAccountsNotifications() -> Observable<(pubkey: String, lamports: SolanaSDK.Lamports)>
}

extension SolanaSDK.Socket: AccountNotificationsRepository {    
    func observeAllAccountsNotifications() -> Observable<(pubkey: String, lamports: SolanaSDK.Lamports)> {
        observeAccountNotifications()
    }
}
