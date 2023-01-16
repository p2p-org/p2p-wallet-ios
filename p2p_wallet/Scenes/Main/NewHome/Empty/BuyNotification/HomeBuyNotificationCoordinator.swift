import Combine
import Foundation
import Resolver
import SolanaSwift
import SwiftUI

enum HomeBuyNotificationCoordinatorResult {
    case showBuy
    case cancel
}

final class HomeBuyNotificationCoordinator: Coordinator<HomeBuyNotificationCoordinatorResult> {
    private let transition = PanelTransition()
    private let result = PassthroughSubject<HomeBuyNotificationCoordinatorResult, Never>()
    let controller: UIViewController
    let tokenFrom: Token
    let tokenTo: Token

    init(tokenFrom: Token, tokenTo: Token, controller: UIViewController) {
        self.tokenFrom = tokenFrom
        self.tokenTo = tokenTo
        self.controller = controller
    }

    override func start() -> AnyPublisher<HomeBuyNotificationCoordinatorResult, Never> {
        let view = HomeBuyNotificationView(
            sourceSymbol: tokenFrom.symbol,
            destinationSymbol: tokenTo.symbol
        ) { [weak self] in
            self?.result.send(.showBuy)
        }
        let viewController = UIHostingController(rootView: view)
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        controller.present(viewController, animated: true)

        viewController.onClose = { [weak self] in
            self?.result.send(.cancel)
        }

        return
            Publishers.MergeMany(
                result.eraseToAnyPublisher(),
                transition.dimmClicked
                    .map { HomeBuyNotificationCoordinatorResult.cancel }.eraseToAnyPublisher()
            )
            .handleEvents(receiveOutput: { [weak viewController] _ in
                viewController?.dismiss(animated: true)
            }).prefix(1).eraseToAnyPublisher().eraseToAnyPublisher()
    }
}
