//
//  WLNotificationsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/07/2021.
//

import Foundation
import RxSwift

enum WLNotification: Equatable {
    case sent(account: String, lamports: SolanaSDK.Lamports)
    case received(account: String, lamports: SolanaSDK.Lamports)
}

protocol WLNotificationsRepository {
    func getAllNotifications() -> [WLNotification]
    func observeAllNotifications() -> Observable<WLNotification>
}

extension WLNotificationsRepository {
    func observeChange(account: String) -> Observable<WLNotification> {
        observeAllNotifications()
            .filter {
                switch $0 {
                case let .received(receivedAccount, _):
                    return receivedAccount == account
                case let .sent(sentAccount, _):
                    return sentAccount == account
                }
            }
    }
}
