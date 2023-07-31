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
<<<<<<< HEAD
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
=======
        let view = ActionsView()
        transition.containerHeight = view.viewHeight
        let viewController = view.asViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.view.layer.cornerRadius = 16
        viewController.view.clipsToBounds = true
        navigationController.transitioningDelegate = transition
        navigationController.modalPresentationStyle = .custom
        self.viewController.present(navigationController, animated: true)
        
        let subject = PassthroughSubject<ActionsCoordinator.Result, Never>()
        
        transition.dismissed
            .sink(receiveValue: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    subject.send(.cancel)
                }
            })
            .store(in: &subscriptions)
        transition.dimmClicked
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        view.cancel
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)

        view.action
            .sink(receiveValue: { actionType in
                viewController.dismiss(animated: true) {
                    subject.send(.action(type: actionType))
                }
            })
            .store(in: &subscriptions)

        return subject.prefix(1).eraseToAnyPublisher()
>>>>>>> develop
    }
}

// MARK: - Result

extension ActionsCoordinator {
    enum Result {
        case cancel
        case action(type: ActionsViewActionType)
    }
}
