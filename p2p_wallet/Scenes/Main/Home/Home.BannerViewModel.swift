//
// Created by Giang Long Tran on 18.02.2022.
//

import BECollectionView
import Foundation
import RxSwift

extension Home {
    class BannerViewModel: BEListViewModel<Banners.Banner> {
        let disposeBag = DisposeBag()
        var bannerService: Banners.Service

        var banners: [Banners.Banner] = []

        init(service: Banners.Service) {
            bannerService = service
            super.init()

            bannerService.banners.drive(onNext: { [weak self] banners in
                self?.banners = banners
                self?.reload()
            }).disposed(by: disposeBag)
        }

        override func createRequest() -> Single<[Banners.Banner]> {
            .just(banners)
        }
    }
}
