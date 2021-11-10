//
//  SessionBannersAvailabilityState.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.11.2021.
//

import RxSwift
import RxRelay

final class SessionBannersAvailabilityState: BannersAvailabilityStateType {
    let usernameBannerIsAvailableSubject = BehaviorRelay<Bool>(value: true)

    func subject(for bannerKind: BannerKind) -> Observable<Bool> {
        switch bannerKind {
        case .reserveUsername:
            return usernameBannerIsAvailableSubject.asObservable()
        }
    }

    func setNotAvailableState(banner: BannerKind) {
        switch banner {
        case .reserveUsername:
            usernameBannerIsAvailableSubject.accept(false)
        }
    }
}
