import Combine
import Foundation
import Reachability
import Resolver

public extension Reachability {
    var reachabilityChanged: AnyPublisher<Reachability, Never> {
        NotificationCenter.default.publisher(for: Notification.Name.reachabilityChanged)
            .compactMap { $0.object as? Reachability }
            .eraseToAnyPublisher()
    }

    var status: AnyPublisher<Reachability.Connection, Never> {
        reachabilityChanged
            .map(\.connection)
            .eraseToAnyPublisher()
    }
}

public extension Reachability {
    func check() -> Bool {
        print(connection)
        switch connection {
        case .unavailable:
            Resolver.resolve(NotificationService.self).showToast(title: "☕️", text: L10n.noInternetConnection)
            return false
        default:
            return true
        }
    }
}
