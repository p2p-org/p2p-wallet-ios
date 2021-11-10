//
//  BannersAvailabilityStateType.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.11.2021.
//

import RxSwift

protocol BannersAvailabilityStateType: AnyObject {
    func subject(for bannerKind: BannerKind) -> Observable<Bool>
    func setNotAvailableState(banner: BannerKind)
}
