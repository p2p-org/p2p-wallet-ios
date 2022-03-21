//
//  WalletsViewModel+WLNotificationsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/07/2021.
//

import Foundation
import RxSwift

extension WalletsViewModel: WLNotificationsRepository {
    func getAllNotifications() -> [WLNotification] {
        notifications
    }

    func observeAllNotifications() -> Observable<WLNotification> {
        notificationsSubject.filter { $0 != nil }.map { $0! }.asObservable()
    }
}
