import Combine
import SwiftUI
import UIKit

final class TermsAndConditionsCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let result = PassthroughSubject<Void, Never>()
    private let url: URL

    init(navigationController: UINavigationController, url: URL) {
        self.navigationController = navigationController
        self.url = url
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = TermsAndConditionsView(url: url)
        let vc = UIHostingController(rootView: view)
        navigationController.pushViewController(vc, animated: true)
        return result.eraseToAnyPublisher()
    }
}
