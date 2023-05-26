import Combine
import Foundation
import Resolver
import SolanaSwift
import UIKit

final class ActionsCoordinator: Coordinator<ActionsCoordinator.Result> {
    private var viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<ActionsCoordinator.Result, Never> {
        let viewModel = ActionsViewModel()
        let view = ActionsView(viewModel: viewModel)
        let controller = UIBottomSheetHostingController(rootView: view)
        viewController.present(controller, interactiveDismissalType: .standard)
        controller.view.layer.cornerRadius = 20
        return Publishers.Merge(
            controller.deallocatedPublisher().map {
                ActionsCoordinator.Result.cancel
            },
            viewModel.action.map { ActionsCoordinator.Result.action(type: $0) }
                .handleEvents(receiveOutput: { [weak controller] _ in
                    controller?.dismiss(animated: true)
                })
        ).prefix(1).eraseToAnyPublisher()
    }
}

// MARK: - Result

extension ActionsCoordinator {
    enum Result {
        case cancel
        case action(type: ActionsView.Action)
    }
}
