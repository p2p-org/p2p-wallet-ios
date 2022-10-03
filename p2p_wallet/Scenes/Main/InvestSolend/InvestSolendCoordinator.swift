import AnalyticsManager
import Combine
import Foundation
import Resolver
import SafariServices
import SolanaSwift
import SwiftUI

final class InvestSolendCoordinator: Coordinator<Void> {
    let navigationController: UINavigationController
    private let closeSubject = PassthroughSubject<Void, Never>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let investVC = UIHostingControllerWithoutNavigation(rootView: InvestSolendView(viewModel: .init()))
        navigationController.viewControllers = [investVC]
        investVC.onClose = { [weak self] in
            self?.closeSubject.send()
        }
        return closeSubject.prefix(1).eraseToAnyPublisher()
    }
}
