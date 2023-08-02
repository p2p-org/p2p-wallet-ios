import AnalyticsManager
import Combine
import Foundation
import Resolver
import SwiftUI

final class IBANDetailsInfoCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = IBANDetailsInfoViewModel()
        let controller = BottomSheetController(
            rootView: IBANDetailsInfoView(viewModel: viewModel)
        )

        viewModel.close
            .sink { [weak controller] _ in
                controller?.dismiss(animated: true)
            }
            .store(in: &subscriptions)

        navigationController.present(controller, animated: true)

        return Publishers.Merge(
            controller.deallocatedPublisher()
                .eraseToAnyPublisher(),
            viewModel.close
                .eraseToAnyPublisher()
        )
        .prefix(1).eraseToAnyPublisher()
    }
}
