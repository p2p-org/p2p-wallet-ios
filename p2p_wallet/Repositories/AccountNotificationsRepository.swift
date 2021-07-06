//
//  AccountNotificationsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/07/2021.
//

import Foundation
import RxSwift

protocol AccountNotificationsRepository {
    func observeAccountNotifications(account: String) -> Observable<SolanaSDK.Lamports>
}

extension SolanaSDK.Socket: AccountNotificationsRepository {
    func observeAccountNotifications(account: String) -> Observable<SolanaSDK.Lamports> {
        observeAccountNotifications().filter {$0.pubkey == account}
            .map {$0.lamports}.distinctUntilChanged()
    }
}
