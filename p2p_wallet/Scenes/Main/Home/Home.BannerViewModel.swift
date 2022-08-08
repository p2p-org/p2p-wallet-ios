//
// Created by Giang Long Tran on 18.02.2022.
//

import BECollectionView_Combine
import Combine
import Foundation

extension Home {
    class BannerViewModel: BECollectionViewModel<Banners.Banner> {
        var subscriptions = [AnyCancellable]()
        var bannerService: Banners.Service

        var banners: [Banners.Banner] = []

        init(service: Banners.Service) {
            bannerService = service
            super.init()

            bannerService.banners.sink { [weak self] banners in
                self?.banners = banners
                self?.reload()
            }.store(in: &subscriptions)
        }

        override func createRequest() async throws -> [Banners.Banner] {
            banners
        }
    }
}
