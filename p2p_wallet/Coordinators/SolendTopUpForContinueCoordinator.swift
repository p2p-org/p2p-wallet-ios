//
//  InvestSolendBlindCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 27.09.2022.
//

import Combine
import SolanaSwift
import UIKit

final class SolendTopUpForContinueCoordinator: Coordinator<SolendTopUpForContinueCoordinator.Result> {
    typealias Model = SolendTopUpForContinueModel

    private let navigationController: UINavigationController
    private let model: SolendTopUpForContinueModel

    private let transition = PanelTransition()

    init(
        navigationController: UINavigationController,
        model: SolendTopUpForContinueModel
    ) {
        self.navigationController = navigationController
        self.model = model
    }

    override func start() -> AnyPublisher<SolendTopUpForContinueCoordinator.Result, Never> {
        let resultSubject = PassthroughSubject<Result, Never>()

        let viewModel = SolendTopUpForContinueViewModel(model: model)
        let view = SolendTopUpForContinueView(viewModel: viewModel)
        transition.containerHeight = view.viewHeight
        let viewController = view.asViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.view.layer.cornerRadius = 16
        navigationController.transitioningDelegate = transition
        navigationController.modalPresentationStyle = .custom
        self.navigationController.present(navigationController, animated: true)

        transition.dimmClicked
            .merge(with: viewModel.close)
            .sink(receiveValue: { _ in
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        viewModel.buy
            .sink(receiveValue: { [unowned self] in
                viewController.dismiss(animated: true)
                resultSubject.send(.showBuy(symbol: model.asset.symbol))
            })
            .store(in: &subscriptions)
        viewModel.receive
            .flatMap { [unowned self] _ in
                coordinate(to: ReceiveCoordinator(
                    network: .solana(tokenSymbol: "SOL", tokenImage: .image(.solanaIcon)),
                    navigationController: navigationController
                ))
            }
            .sink(receiveValue: {})
            .store(in: &subscriptions)

        viewModel.swap
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
                resultSubject.send(.showTrade)
            })
            .store(in: &subscriptions)

        viewController.onClose = {
            resultSubject.send(.close)
        }
        return resultSubject.eraseToAnyPublisher()
    }
}

// MARK: - Result

extension SolendTopUpForContinueCoordinator {
    enum Result {
        case close
        case showTrade
        case showBuy(symbol: String)
    }
}
