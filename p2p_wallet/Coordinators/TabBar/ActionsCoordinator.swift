//
//  ActionsCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 18.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift
import UIKit

final class ActionsCoordinator: Coordinator<ActionsCoordinator.Result> {
    @Injected private var walletsRepository: WalletsRepository
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
            .sink(receiveValue: { [unowned self] actionType in
                switch actionType {
                case .buy:
                    viewController.dismiss(animated: true) {
                        subject.send(.action(type: .buy))
                    }
                case .receive:
                    guard let pubkey = try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) else { return }
                    let coordinator = ReceiveCoordinator(navigationController: navigationController, pubKey: pubkey)
                    coordinate(to: coordinator)
                        .sink { _ in }
                        .store(in: &subscriptions)
                    analyticsManager.log(event: .actionButtonReceive)
                    analyticsManager.log(event: .mainScreenReceiveOpen)
                    analyticsManager.log(event: .receiveViewed(fromPage: "Main_Screen"))
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
                    analyticsManager.log(event: .sendStartScreenOpen(lastScreen: "Action_Panel"))
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
