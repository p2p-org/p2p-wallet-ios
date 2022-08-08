//
// Created by Giang Long Tran on 18.02.2022.
//

import Combine
import Foundation

class BannerServiceImpl: ObservableObject, Banners.Service {
    private var _banners: Set<Banners.Banner> = []
    private var _handler: [Banners.Handler] = []

    init(handlers: [Banners.Handler]) {
        for handler in handlers {
            register(handler: handler)
        }
    }

    @Published private var bannersSubject: Set<Banners.Banner> = []
    var banners: AnyPublisher<[Banners.Banner], Never> {
        $bannersSubject
            .map { $0.sorted { a, b in a.priority.rawValue >= b.priority.rawValue } }
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    func register(handler: Banners.Handler) {
        handler.onRegister(with: self)
        _handler.append(handler)
    }

    func update(banner: Banners.Banner) {
        debugPrint(banner)
        _banners.insert(banner)
        bannersSubject = _banners
    }

    func remove(bannerId: String) {
        _banners = _banners.filter { banner in banner.id != bannerId }
        bannersSubject = _banners
    }
}
