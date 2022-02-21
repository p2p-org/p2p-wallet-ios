//
// Created by Giang Long Tran on 18.02.2022.
//

import Foundation
import RxSwift
import BECollectionView

extension Home {
    class BannerViewModel: BEListViewModel<Banners.Banner> {
        let disposeBag = DisposeBag()
        @Injected var bannerService: Banners.Service
        
        var banners: [Banners.Banner] = []
        
        init() {
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