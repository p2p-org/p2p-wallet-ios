//
//  WalletDetailCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 13.11.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver

final class WalletDetailCoordinator: Coordinator<WalletDetailCoordinator.Result> {
    // MARK: - Properties

    private let navigationController: UINavigationController
    private let model: Model
    private let analyticsManager: AnalyticsManager

    private let subject = PassthroughSubject<WalletDetailCoordinator.Result, Never>()

    // MARK: - Initializer

    init(
        navigationController: UINavigationController,
        model: Model,
        analyticsManager: AnalyticsManager = Resolver.resolve()
    ) {
        self.navigationController = navigationController
        self.model = model
        self.analyticsManager = analyticsManager
    }

    override func start() -> AnyPublisher<WalletDetailCoordinator.Result, Never> {
        analyticsManager.log(event: AmplitudeEvent.mainScreenTokenDetailsOpen(tokenTicker: model.symbol))
        let viewModel = WalletDetail.ViewModel(pubkey: model.pubKey, symbol: model.symbol)
        let view = WalletDetail.ViewController(viewModel: viewModel)

        view.processingTransactionDoneHandler = { [weak self] in
            self?.navigationController.popToRootViewController(animated: true)
            self?.subject.send(.done)
        }
        view.onClose = { [weak self] in
            self?.subject.send(.cancel)
        }

        navigationController.show(view, sender: nil)

        return subject.prefix(1).eraseToAnyPublisher()
    }
}

// MARK: - Model

extension WalletDetailCoordinator {
    struct Model {
        let pubKey: String
        let symbol: String
    }
}

// MARK: - Result

extension WalletDetailCoordinator {
    enum Result {
        case cancel
        case done
    }
}
