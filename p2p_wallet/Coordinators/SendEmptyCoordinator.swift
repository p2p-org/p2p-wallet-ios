//
//  SendEmptyCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 07.12.2022.
//

import Combine
import Foundation
import UIKit
import SolanaSwift
import Resolver

final class SendEmptyCoordinator: Coordinator<Void> {
    @Injected private var walletsRepository: WalletsRepository

    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SendEmptyView(
            buyCrypto: {
                let coordinator = BuyCoordinator(
                    navigationController: self.navigationController,
                    context: .fromHome
                )
                self.coordinate(to: coordinator)
                    .sink { _ in }
                    .store(in: &self.subscriptions)
            },
            receive: {
                guard
                    let pubKey = try? PublicKey(string: self.walletsRepository.nativeWallet?.pubkey)
                else { return }
                let coordinator = ReceiveCoordinator(navigationController: self.navigationController, pubKey: pubKey)
                self.coordinate(to: coordinator)
                    .sink { _ in }
                    .store(in: &self.subscriptions)
            }
        )
        let viewController = view.asViewController(withoutUIKitNavBar: false)
        viewController.hidesBottomBarWhenPushed = true
        viewController.navigationItem.title = L10n.buyOrReceiveCryptoToContinue
        navigationController.pushViewController(viewController, animated: true)

        let resultSubject = PassthroughSubject<Void, Never>()
        viewController.onClose = {
            resultSubject.send()
        }
        return resultSubject.prefix(1).eraseToAnyPublisher()
    }
}
