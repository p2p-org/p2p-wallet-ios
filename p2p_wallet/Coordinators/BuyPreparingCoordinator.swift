//
//  BuyPreparingCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 04.08.2022.
//

import Combine
import Foundation
import Resolver
import UIKit

final class BuyPreparingCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let strategy: Strategy
    private let crypto: Buy.CryptoCurrency

    init(navigationController: UINavigationController, strategy: Strategy, crypto: Buy.CryptoCurrency) {
        self.navigationController = navigationController
        self.strategy = strategy
        self.crypto = crypto
    }

    override func start() -> AnyPublisher<Void, Never> {
        let vc = BuyPreparing.Scene(
            viewModel: BuyPreparing.SceneModel(
                crypto: crypto,
                exchangeService: Resolver.resolve()
            )
        )
        switch strategy {
        case .show:
            navigationController.show(vc, sender: nil)
        case .present:
            let navigation = UINavigationController(rootViewController: vc)
            navigationController.present(navigation, animated: true)
        }

        let subject = PassthroughSubject<Void, Never>()
        vc.onClose = {
            subject.send()
        }
        return subject.eraseToAnyPublisher()
    }
}

extension BuyPreparingCoordinator {
    enum Strategy {
        case show
        case present
    }
}
