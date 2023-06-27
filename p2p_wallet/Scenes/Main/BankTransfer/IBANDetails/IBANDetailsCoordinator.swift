import SwiftUI
import Combine

final class IBANDetailsCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = IBANDetailsViewModel()
        let view = IBANDetailsView(viewModel: viewModel)

        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.hidesBottomBarWhenPushed = true
        vc.title = L10n.euroAccount

        navigationController.pushViewController(vc, animated: true)

        return vc.deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
