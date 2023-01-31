import Combine
import Foundation
import UIKit

final class NetworkCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = NetworkViewModel()
        let viewController = BottomSheetController(title: L10n.network, rootView: NetworkView(viewModel: viewModel))
        viewController.modalPresentationStyle = .custom
        navigationController.present(viewController, animated: true)

        return Publishers.Merge(
            viewModel.dismiss.handleEvents(receiveOutput: { _ in
                viewController.dismiss(animated: true)
            }),
            viewController.deallocatedPublisher()
        ).prefix(1).eraseToAnyPublisher()
    }
}
