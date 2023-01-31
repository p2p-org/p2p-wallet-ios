import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift
import UIKit

final class ActionsCoordinator: Coordinator<ActionsCoordinator.Result> {
    @Injected private var analyticsManager: AnalyticsManager

    private unowned var viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<ActionsCoordinator.Result, Never> {
        let view = ActionsView()
        let viewController = BottomSheetController(title: L10n.actions, rootView: view)
        viewController.modalPresentationStyle = .custom
        viewController.preferredSheetSizing = .fit
        self.viewController.present(viewController, animated: true)

        let result = Publishers.Merge(
            view.cancel.map { ActionsCoordinator.Result.cancel },
            view.action.map { ActionsCoordinator.Result.action(type: $0) }
        )

        return Publishers.Merge(
            result.handleEvents(receiveOutput: { [weak self] action in
                switch action {
                case .action(let type):
                    self?.logAnalytics(for: type)
                default: break
                }
                self?.viewController.dismiss(animated: true)
            }),
            viewController.deallocatedPublisher().map { ActionsCoordinator.Result.cancel }
        ).prefix(1).eraseToAnyPublisher()
    }

    private func logAnalytics(for actionType: ActionsView.Action) {
        switch actionType {
        case .buy:
            break
        case .receive:
            analyticsManager.log(event: AmplitudeEvent.actionButtonReceive)
            analyticsManager.log(event: AmplitudeEvent.mainScreenReceiveOpen)
            analyticsManager.log(event: AmplitudeEvent.receiveViewed(fromPage: "Main_Screen"))
        case .swap:
            analyticsManager.log(event: AmplitudeEvent.actionButtonSwap)
            analyticsManager.log(event: AmplitudeEvent.mainScreenSwapOpen)
            analyticsManager.log(event: AmplitudeEvent.swapViewed(lastScreen: "Main_Screen"))
        case .send:
            analyticsManager.log(event: AmplitudeEvent.actionButtonSend)
            analyticsManager.log(event: AmplitudeEvent.mainScreenSendOpen)
            analyticsManager.log(event: AmplitudeEvent.sendViewed(lastScreen: "Main_Screen"))
        case .cashOut:
            analyticsManager.log(event: AmplitudeEvent.sellClicked(source: "Action_Panel"))
        }
    }
}

// MARK: - Result

extension ActionsCoordinator {
    enum Result {
        case cancel
        case action(type: ActionsView.Action)
    }
}
