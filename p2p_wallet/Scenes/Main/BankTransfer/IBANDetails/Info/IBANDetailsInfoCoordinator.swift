import AnalyticsManager
import Combine
import Foundation
import Resolver
import SwiftUI

enum IBANDetailsInfoResult {
    case dontShowAgain
    case cancel
}

final class IBANDetailsInfoCoordinator: Coordinator<IBANDetailsInfoResult> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<IBANDetailsInfoResult, Never> {
        let viewModel = IBANDetailsInfoViewModel()
        let controller = BottomSheetController(
            rootView: IBANDetailsInfoView(viewModel: viewModel)
        )
        navigationController.present(controller, animated: true)

        return controller.deallocatedPublisher()
            .map { IBANDetailsInfoResult.cancel }.eraseToAnyPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
