import AnalyticsManager
import Combine
import Foundation
import KeyAppUI
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
        controller.view.backgroundColor = Asset.Colors.smoke.color
        viewModel.close
            .sink { [weak controller] _ in
                controller?.dismiss(animated: true)
            }
            .store(in: &subscriptions)

        navigationController.present(controller, animated: true)

        return controller
            .deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
