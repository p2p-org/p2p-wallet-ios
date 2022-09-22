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

final class ActionsCoordinator: Coordinator<Void> {
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var analyticsManager: AnalyticsManager

    private let viewController: UIViewController

    private let transition = PanelTransition()

    private var sendCoordinator: SendToken.Coordinator?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = ActionsView()
        transition.containerHeight = view.viewHeight
        let viewController = view.asViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.view.layer.cornerRadius = 16
        navigationController.transitioningDelegate = transition
        navigationController.modalPresentationStyle = .custom
        self.viewController.present(navigationController, animated: true)

        let subject = PassthroughSubject<Void, Never>()
        transition.dimmClicked
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)

        navigationController.onClose = {
            subject.send()
        }
        view.cancel
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        view.action
            .sink(receiveValue: { [unowned self] actionType in
                switch actionType {
                case .buy:
                    // Disabling on
                    if available(.buyScenarioEnabled) {
                        let coordinator = BuyCoordinator(
                            context: .fromHome,
                            presentingViewController: viewController,
                            shouldPush: false
                        )
                        coordinate(to: coordinator)
                            .sink { _ in }
                            .store(in: &subscriptions)
                    } else {
                        navigationController.present(
                            BuyTokenSelection.Scene(onTap: { [unowned self] in
                                let coordinator = BuyPreparingCoordinator(
                                    navigationController: navigationController,
                                    strategy: .present,
                                    crypto: $0
                                )
                                coordinate(to: coordinator)
                            }),
                            animated: true
                        )
                    }
                case .receive:
                    guard let pubkey = try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) else { return }
                    let coordinator = ReceiveCoordinator(navigationController: navigationController, pubKey: pubkey)
                    coordinate(to: coordinator).sink { _ in }.store(in: &subscriptions)
                    analyticsManager.log(event: AmplitudeEvent.actionButtonReceive)
                    analyticsManager.log(event: AmplitudeEvent.mainScreenReceiveOpen)
                    analyticsManager.log(event: AmplitudeEvent.receiveViewed(fromPage: "Main_Screen"))
                case .trade:
                    let vm = OrcaSwapV2.ViewModel(initialWallet: nil)
                    let vc = OrcaSwapV2.ViewController(viewModel: vm)
                    let navigation = UINavigationController(rootViewController: vc)
                    analyticsManager.log(event: AmplitudeEvent.actionButtonSwap)
                    analyticsManager.log(event: AmplitudeEvent.mainScreenSwapOpen)
                    analyticsManager.log(event: AmplitudeEvent.swapViewed(lastScreen: "Main_Screen"))
                    vc.doneHandler = { [weak self] in
                        self?.viewController.dismiss(animated: true)
                    }
                    navigationController.present(navigation, animated: true)
                case .send:
                    let vm = SendToken.ViewModel(
                        walletPubkey: walletsRepository.nativeWallet?.pubkey,
                        destinationAddress: nil,
                        relayMethod: .default
                    )
                    sendCoordinator = SendToken.Coordinator(
                        viewModel: vm,
                        navigationController: navigationController
                    )
                    analyticsManager.log(event: AmplitudeEvent.actionButtonSend)
                    analyticsManager.log(event: AmplitudeEvent.mainScreenSendOpen)
                    analyticsManager.log(event: AmplitudeEvent.sendViewed(lastScreen: "Main_Screen"))

                    sendCoordinator?.doneHandler = { [weak self] in
                        self?.viewController.dismiss(animated: true)
                    }
                    sendCoordinator?.start(hidesBottomBarWhenPushed: true, push: false)
                }
            })
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }
}
