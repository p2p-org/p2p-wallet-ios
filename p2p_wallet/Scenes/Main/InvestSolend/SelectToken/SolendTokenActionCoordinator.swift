//
//  SolendTokenActionCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 29.09.2022.
//

import Combine
import Resolver
import UIKit

final class SolendTokenActionCoordinator: Coordinator<SolendTokenActionCoordinator.Result> {
    private let controller: UIViewController
    private let strategy: Strategy

    private let transition = PanelTransition()

    init(
        controller: UIViewController,
        strategy: Strategy
    ) {
        self.controller = controller
        self.strategy = strategy
    }

    override func start() -> AnyPublisher<SolendTokenActionCoordinator.Result, Never> {
        let viewController: UIViewController
        let view: SolendSelectTokenView
        let resultSubject = PassthroughSubject<SolendTokenActionCoordinator.Result, Never>()

        switch strategy {
        case let .tokenToDeposit(model):
            view = TokenToDepositView(models: model)
            viewController = (view as! TokenToDepositView).asViewController()
        case let .tokenToWithdraw(model):
            view = TokenToWithdrawView(models: model)
            viewController = (view as! TokenToWithdrawView).asViewController()
        }
        transition.containerHeight = view.viewHeight
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        controller.present(viewController, animated: true)

        view.symbol
            .sink(receiveValue: {
                resultSubject.send(.symbol($0))
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        view.close
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        transition.dimmClicked
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        viewController.onClose = {
            resultSubject.send(.close)
        }

        return resultSubject.eraseToAnyPublisher()
    }
}

// MARK: - Strategy

extension SolendTokenActionCoordinator {
    enum Strategy {
        case tokenToDeposit(model: [TokenToDepositView.Model])
        case tokenToWithdraw(model: [TokenToWithdrawView.Model])
    }
}

// MARK: - Result

extension SolendTokenActionCoordinator {
    enum Result {
        case close
        case symbol(String)
    }
}
