//
//  SendEmptyCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 07.12.2022.
//

import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import Resolver
import SolanaSwift
import UIKit

final class SendEmptyCoordinator: Coordinator<Void> {
    @Injected private var analyticsManager: AnalyticsManager

    private let navigationController: UINavigationController
    private let flow: SendFlow

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        flow = .send
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SendEmptyView(
            buyCrypto: {
                self.log(event: .sendnewBuyClickButton(source: self.flow.rawValue))
                let coordinator = BuyCoordinator(
                    navigationController: self.navigationController,
                    context: .fromHome
                )
                self.coordinate(to: coordinator)
                    .sink { _ in }
                    .store(in: &self.subscriptions)
            },
            receive: {
                self.log(event: .sendnewReceiveClickButton(source: self.flow.rawValue))
                if available(.ethAddressEnabled) {
                    let coordinator =
                        SupportedTokensCoordinator(presentation: SmartCoordinatorPushPresentation(self
                                .navigationController))
                    self.coordinate(to: coordinator)
                        .sink { _ in }
                        .store(in: &self.subscriptions)
                } else {
                    let coordinator = ReceiveCoordinator(
                        network: .solana(tokenSymbol: "SOL", tokenImage: .image(.solanaIcon)),
                        navigationController: self.navigationController
                    )
                    self.coordinate(to: coordinator)
                        .sink { _ in }
                        .store(in: &self.subscriptions)
                }
            }
        )
        let viewController = view.asViewController(withoutUIKitNavBar: false)
        viewController.hidesBottomBarWhenPushed = true
        viewController.navigationItem.title = L10n.buyOrReceiveToContinue
        navigationController.pushViewController(viewController, animated: true)

        let resultSubject = PassthroughSubject<Void, Never>()
        viewController.onClose = {
            resultSubject.send()
        }
        return resultSubject.prefix(1).eraseToAnyPublisher()
    }

    private func log(event: KeyAppAnalyticsEvent) {
        analyticsManager.log(event: event)
    }
}
