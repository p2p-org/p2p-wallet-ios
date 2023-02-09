import AnalyticsManager
import Combine
import Foundation
import Resolver
import UIKit
import SwiftUI
import KeyAppUI

final class ActionsCoordinator: Coordinator<ActionsCoordinator.Result> {

    @Injected private var analyticsManager: AnalyticsManager

    private unowned var viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<ActionsCoordinator.Result, Never> {
        let viewModel = ActionsViewModel()
        let view = ActionsView(viewModel: viewModel)
        let viewController = BottomSheetController(
            title: L10n.actions,
            backgroundColor: Color(UIColor.f2F5Fa),
            handlerColor: Color(UIColor._9799Af),
            cornerRadius: 18.0,
            rootView: view
        )
        self.viewController.present(viewController, animated: true)

        viewModel.coordinatorIO.action
            .sink(receiveValue: { [unowned self] actionType in
                switch actionType {
                case .buy:
                    break
                case .receive:
                    analyticsManager.log(event: .actionButtonReceive)
                    analyticsManager.log(event: .mainScreenReceiveOpen)
                    analyticsManager.log(event: .receiveViewed(fromPage: "Main_Screen"))
                case .swap:
                    analyticsManager.log(event: .actionButtonSwap)
                    analyticsManager.log(event: .mainScreenSwapOpen)
                    analyticsManager.log(event: .swapViewed(lastScreen: "Main_Screen"))
                case .send:
                    analyticsManager.log(event: .actionButtonSend)
                    analyticsManager.log(event: .mainScreenSendOpen)
                    analyticsManager.log(event: .sendViewed(lastScreen: "Main_Screen"))
                case .cashOut:
                    analyticsManager.log(event: .sellClicked(source: "Action_Panel"))
                }
            })
            .store(in: &subscriptions)

        return Publishers.Merge(
            Publishers.Merge(
                viewModel.coordinatorIO.action.map { ActionsCoordinator.Result.action(type: $0) },
                viewModel.coordinatorIO.close.map { ActionsCoordinator.Result.cancel }
            )
                .handleEvents(receiveOutput: { [weak viewController] val in
                    viewController?.dismiss(animated: true)
                }),
            viewController.deallocatedPublisher().map { ActionsCoordinator.Result.cancel }
        )
            .prefix(1)
            .eraseToAnyPublisher()
    }
}

// MARK: - Result

extension ActionsCoordinator {
    enum Result {
        case cancel
        case action(type: ActionsViewModel.Action)
    }
}
