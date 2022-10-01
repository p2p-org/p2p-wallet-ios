//
//  InvestSolendBlindCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 27.09.2022.
//

import Combine
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
            .sink(receiveValue: {
                // TODO: - Buy flow
            })
            .store(in: &subscriptions)
        viewModel.receive
            .sink(receiveValue: { [unowned self] in
                let coordinator = ReceiveCoordinator(
                    navigationController: navigationController,
                    pubKey: $0
                )
                coordinate(to: coordinator)
            })
            .store(in: &subscriptions)

        let resultSubject = PassthroughSubject<Result, Never>()
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
    }
}
