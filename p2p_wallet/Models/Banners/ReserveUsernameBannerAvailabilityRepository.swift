//
//  ReserveUsernameBannerAvailabilityRepository.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.11.2021.
//

import RxSwift

protocol ReserveUsernameBannerAvailabilityRepositoryType: AnyObject {
    func removeForever(bannerKind: BannerKind)
    func removeForSession(bannerKind: BannerKind)
    func availabilitySubject() -> Observable<Bool>
}

final class ReserveUsernameBannerAvailabilityRepository: ReserveUsernameBannerAvailabilityRepositoryType {
    private let bannerKind: BannerKind = .reserveUsername

    private let sessionBannersAvailabilityState: BannersAvailabilityStateType
    private let persistentBannersAvailabilityState: BannersAvailabilityStateType
    private let nameStorage: NameStorageType

    init(
        sessionBannersAvailabilityState: BannersAvailabilityStateType,
        persistentBannersAvailabilityState: BannersAvailabilityStateType,
        nameStorage: NameStorageType
    ) {
        self.sessionBannersAvailabilityState = sessionBannersAvailabilityState
        self.persistentBannersAvailabilityState = persistentBannersAvailabilityState
        self.nameStorage = nameStorage
    }

    func removeForever(bannerKind: BannerKind) {
        persistentBannersAvailabilityState.setNotAvailableState(banner: bannerKind)
    }

    func removeForSession(bannerKind: BannerKind) {
        sessionBannersAvailabilityState.setNotAvailableState(banner: bannerKind)
    }

    func availabilitySubject() -> Observable<Bool> {
        Observable.combineLatest(
            [
                sessionBannersAvailabilityState.subject(for: bannerKind),
                persistentBannersAvailabilityState.subject(for: bannerKind),
                .just(nameStorage.getName() == nil)
            ]
        )
            .map { $0.allSatisfy { $0 } }
    }
}
