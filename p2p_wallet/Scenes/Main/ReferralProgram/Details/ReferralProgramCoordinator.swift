import Combine
import SwiftUI
import UIKit

final class ReferralProgramCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let result = PassthroughSubject<Void, Never>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = ReferralProgramView(viewModel: ReferralProgramViewModel())
        let vc = UIHostingController(rootView: view)
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)

        return result.eraseToAnyPublisher()
    }
}
