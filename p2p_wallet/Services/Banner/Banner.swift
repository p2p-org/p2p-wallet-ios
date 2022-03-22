//
// Created by Giang Long Tran on 18.02.2022.
//

import Foundation
import RxCocoa
import RxSwift

class Banners {
    typealias Service = BannerServiceType
    typealias Handler = BannerHandlerType
    typealias Action = BannerAction

    enum Priority: Int {
        case low = 1
        case medium = 2
        case hight = 3
        case veryHigh = 4
    }

    enum Actions {
        struct OpenScreen: Action {
            let screen: String
        }
    }

    class Banner: Hashable {
        enum InfoKey {
            case title
            case action
            case icon
            case background
        }

        let id: String
        let priority: Banners.Priority
        let onTapAction: Action?

        init(id: String, priority: Priority, onTapAction: Action? = nil) {
            self.id = id
            self.priority = priority
            self.onTapAction = onTapAction
        }

        func getInfo() -> [InfoKey: Any] { [:] }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: Banner, rhs: Banner) -> Bool {
            if lhs === rhs { return true }
            if type(of: lhs) != type(of: rhs) { return false }
            if lhs.id != rhs.id { return false }
            return true
        }
    }
}

protocol BannerServiceType: AnyObject {
    var banners: Driver<[Banners.Banner]> { get }

    func register(handler: Banners.Handler)
    func unregister(handler: Banners.Handler)

    func update(banner: Banners.Banner)
    func remove(bannerId: String)
}

protocol BannerHandlerType: AnyObject {
    func onRegister(with service: Banners.Service)
}

protocol BannerAction {}
