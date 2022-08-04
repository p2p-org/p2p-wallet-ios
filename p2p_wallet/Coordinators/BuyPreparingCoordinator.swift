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
    private let crypto: Buy.CryptoCurrency

    init(navigationController: UINavigationController, crypto: Buy.CryptoCurrency) {
        self.navigationController = navigationController
        self.crypto = crypto
    }

    override func start() -> AnyPublisher<Void, Never> {
        let vc = BuyPreparing.Scene(
            viewModel: BuyPreparing.SceneModel(
                crypto: crypto,
                exchangeService: Resolver.resolve()
            )
        )
        navigationController.show(vc, sender: nil)
        return Empty(completeImmediately: false)
            .eraseToAnyPublisher()
    }
}
