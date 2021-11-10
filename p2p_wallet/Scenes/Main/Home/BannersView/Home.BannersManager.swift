//
//  Home.BannersManager.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.11.2021.
//

import RxSwift
import RxRelay

enum BannerKind {
    case reserveUsername
}

protocol BannersRepositoryType: AnyObject {
    var actualBannersSubject: BehaviorRelay<[BannerKind]> { get }
    func removeForever(bannerKind: BannerKind)
    func removeForSession(bannerKind: BannerKind)
}

final class BannersRepository: BannersRepositoryType {
    let actualBannersSubject = BehaviorRelay<[BannerKind]>(value: [])
    private let sessionBannersAvailabilityState: BannersAvailabilityStateType
    private let persistentBannersAvailabilityState: BannersAvailabilityStateType
    private let disposeBag = DisposeBag()

    private let possibleBanners: [BannerKind] = [.reserveUsername]

    init(
        sessionBannersAvailabilityState: BannersAvailabilityStateType,
        persistentBannersAvailabilityState: BannersAvailabilityStateType
    ) {
        self.sessionBannersAvailabilityState = sessionBannersAvailabilityState
        self.persistentBannersAvailabilityState = persistentBannersAvailabilityState

        bind()
    }

    func removeForever(bannerKind: BannerKind) {
        persistentBannersAvailabilityState.setNotAvailableState(banner: bannerKind)
    }

    func removeForSession(bannerKind: BannerKind) {
        sessionBannersAvailabilityState.setNotAvailableState(banner: bannerKind)
    }

    private func bind() {
        let bannersAvailabilitySubjects = possibleBanners
            .map(observableAvailability)

        Observable.combineLatest(bannersAvailabilitySubjects).distinctUntilChanged()
            .map { [possibleBanners] availabilities in
                zip(possibleBanners, availabilities)
                    .filter(\.1)
                    .map(\.0)
            }
            .subscribe(onNext: { [weak self] in
                self?.actualBannersSubject.accept($0)
            })
            .disposed(by: disposeBag)
    }

    private func observableAvailability(bannerKind: BannerKind) -> Observable<Bool> {
        switch bannerKind {
        case .reserveUsername:
            return combine(
                states: [sessionBannersAvailabilityState, persistentBannersAvailabilityState],
                bannerKind: .reserveUsername
            )
        }
    }

    private func combine(states: [BannersAvailabilityStateType], bannerKind: BannerKind) -> Observable<Bool> {
        Observable.combineLatest(
            states.map {
                $0.subject(for: bannerKind)
            }
        )
            .map { $0.allSatisfy { $0 } }
    }
}
