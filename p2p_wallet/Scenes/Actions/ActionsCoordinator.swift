import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift
import UIKit

final class ActionsCoordinator: Coordinator<ActionsCoordinator.Result> {
    @Injected private var analyticsManager: AnalyticsManager

    private unowned var viewController: UIViewController

    private let transition = PanelTransition()

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<ActionsCoordinator.Result, Never> {
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
    }
}

// MARK: - Result

extension ActionsCoordinator {
    enum Result {
        case cancel
        case action(type: ActionsViewActionType)
    }
}
