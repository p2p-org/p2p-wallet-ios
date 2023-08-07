import AnalyticsManager
import Combine
import Foundation
import Resolver
import SwiftUI

enum TopupCoordinatorResult {
    case action(action: TopupActionsViewModel.Action)
    case cancel
}

final class TopupCoordinator: Coordinator<TopupCoordinatorResult> {
    private var viewController: UIViewController!

    @Injected private var analyticsManager: AnalyticsManager

    init(
        viewController: UIViewController? = nil
    ) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<TopupCoordinatorResult, Never> {
        let viewModel = TopupActionsViewModel()
        let controller = BottomSheetController(
            rootView: TopupActionsView(viewModel: viewModel)
        )
        viewController?.present(controller, animated: true)

        return Publishers.Merge(
            // Cancel event
            controller.deallocatedPublisher()
                .map { TopupCoordinatorResult.cancel }.eraseToAnyPublisher(),
            // Tapped item
            viewModel.tappedItem
                .map { TopupCoordinatorResult.action(action: $0) }
                .receive(on: RunLoop.main)
                .handleEvents(receiveOutput: { [weak controller] _ in
                    controller?.dismiss(animated: true)
                })
                .eraseToAnyPublisher()
        )
        .prefix(1).eraseToAnyPublisher()
    }
}
