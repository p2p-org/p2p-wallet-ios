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

protocol BannersManagerType: AnyObject {
    var actualBannersSubject: BehaviorRelay<[BannerKind]> { get }
    func removeForever(bannerKind: BannerKind)
    func removeForSession(bannerKind: BannerKind)
}

final class BannersManager: BannersManagerType {
    let actualBannersSubject = BehaviorRelay<[BannerKind]>(value: [])
    private let usernameBannerRepository: ReserveUsernameBannerAvailabilityRepositoryType
    private let disposeBag = DisposeBag()

    private let possibleBanners: [BannerKind] = [.reserveUsername]

    init(usernameBannerRepository: ReserveUsernameBannerAvailabilityRepositoryType) {
        self.usernameBannerRepository = usernameBannerRepository

        bind()
    }

    func removeForever(bannerKind: BannerKind) {
        switch bannerKind {
        case .reserveUsername:
            usernameBannerRepository.removeForever(bannerKind: bannerKind)
        }
    }

    func removeForSession(bannerKind: BannerKind) {
        switch bannerKind {
        case .reserveUsername:
            usernameBannerRepository.removeForSession(bannerKind: bannerKind)
        }
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
            return usernameBannerRepository.availabilitySubject()
        }
    }
}
