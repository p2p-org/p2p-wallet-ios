//
//  PersistentBannersAvailabilityState.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.11.2021.
//

import RxSwift
import RxRelay

final class PersistentBannersAvailabilityState: BannersAvailabilityStateType {
    private let usernameBannerIsAvailableSubject = BehaviorRelay<Bool>(value: !Defaults.forceCloseNameServiceBanner)
    private var disposables: [DefaultsDisposable] = []

    init() {
        bind()
    }

    func subject(for bannerKind: BannerKind) -> Observable<Bool> {
        switch bannerKind {
        case .reserveUsername:
            return usernameBannerIsAvailableSubject.asObservable()
        }
    }

    func setNotAvailableState(banner: BannerKind) {
        switch banner {
        case .reserveUsername:
            Defaults.forceCloseNameServiceBanner = true
        }
    }

    private func bind() {
        disposables.append(Defaults.observe(\.forceCloseNameServiceBanner) { [weak self] update in
            let isAvailable = !(update.newValue ?? false)
            self?.usernameBannerIsAvailableSubject.accept(isAvailable)
        })
    }
}
