//
//  SwapCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 13.11.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

final class SwapCoordinator: Coordinator<SwapCoordinator.Result> {
    private let navigationController: UINavigationController
    private let initialWallet: Wallet?
    private let analyticsManager: AnalyticsManager

    private let subject = PassthroughSubject<SwapCoordinator.Result, Never>()

    init(
        navigationController: UINavigationController,
        initialWallet: Wallet?,
        analyticsManager: AnalyticsManager = Resolver.resolve()
    ) {
        self.navigationController = navigationController
        self.initialWallet = initialWallet
        self.analyticsManager = analyticsManager
    }

    override func start() -> AnyPublisher<SwapCoordinator.Result, Never> {
        let viewModel = OrcaSwapV2.ViewModel(initialWallet: initialWallet)
        let view = OrcaSwapV2.ViewController(viewModel: viewModel)
        analyticsManager.log(event: AmplitudeEvent.mainScreenSwapOpen)

        view.doneHandler = { [weak self] in
            self?.navigationController.popToRootViewController(animated: true)
            self?.subject.send(.done)
        }
        view.onClose = { [weak self] in
            self?.subject.send(.cancel)
        }
        navigationController.show(view, sender: nil)

        return subject.eraseToAnyPublisher()
    }
}

// MARK: - Result

extension SwapCoordinator {
    enum Result {
        case cancel
        case done
    }
}
