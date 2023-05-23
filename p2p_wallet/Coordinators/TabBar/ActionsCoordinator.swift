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
        let subject = PassthroughSubject<ActionsCoordinator.Result, Never>()
        let controller = BottomSheetController(rootView: view)
        self.viewController.present(controller, animated: true)
        controller.deallocatedPublisher().sink { _ in
            subject.send(.cancel)
        }.store(in: &subscriptions)

        view.action
            .sink(receiveValue: { [unowned self] actionType in
                switch actionType {
                case .buy, .topUp:
                    viewController.dismiss(animated: true) {
                        subject.send(.action(type: actionType))
                    }
                case .receive:
                    analyticsManager.log(event: .actionButtonReceive)
                    analyticsManager.log(event: .mainScreenReceiveOpen)
                    analyticsManager.log(event: .receiveViewed(fromPage: "Main_Screen"))
                    viewController.dismiss(animated: true) {
                        subject.send(.action(type: .receive))
                    }
                case .swap:
                    analyticsManager.log(event: .actionButtonSwap)
                    analyticsManager.log(event: .mainScreenSwapOpen)
                    analyticsManager.log(event: .swapViewed(lastScreen: "Main_Screen"))
                    viewController.dismiss(animated: true) {
                        subject.send(.action(type: .swap))
                    }
                case .send:
                    analyticsManager.log(event: .actionButtonSend)
                    analyticsManager.log(event: .mainScreenSendOpen)
                    analyticsManager.log(event: .sendViewed(lastScreen: "Main_Screen"))
                    viewController.dismiss(animated: true) {
                        subject.send(.action(type: .send))
                    }
                case .cashOut:
                    viewController.dismiss(animated: true) {
                        subject.send(.action(type: .cashOut))
                    }

                    analyticsManager.log(event: .sellClicked(source: "Action_Panel"))
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
        case action(type: ActionsView.Action)
    }
}
