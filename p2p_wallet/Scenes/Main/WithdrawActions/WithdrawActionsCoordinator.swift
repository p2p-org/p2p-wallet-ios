import AnalyticsManager
import Combine
import Foundation
import Resolver
import SwiftUI

final class WithdrawActionsCoordinator: Coordinator<WithdrawActionsCoordinator.Result> {
    private var viewController: UIViewController

    @Injected private var analyticsManager: AnalyticsManager

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<WithdrawActionsCoordinator.Result, Never> {
        let viewModel = WithdrawActionsViewModel()
        let controller = BottomSheetController(
            rootView: WithdrawActionsView(viewModel: viewModel)
        )
        viewController.present(controller, animated: true)

        return Publishers.Merge(
            // Cancel event
            controller.deallocatedPublisher()
                .map { Result.cancel }.eraseToAnyPublisher(),
            // Tapped item
            viewModel.tappedItem
                .map { Result.action(action: $0) }
                .receive(on: RunLoop.main)
                .handleEvents(receiveOutput: { [weak controller] _ in
                    controller?.dismiss(animated: true)
                })
                .eraseToAnyPublisher()
        )
        .prefix(1).eraseToAnyPublisher()
    }
}

extension WithdrawActionsCoordinator {
    enum Result {
        case action(action: WithdrawActionsViewModel.Action)
        case cancel
    }
}
