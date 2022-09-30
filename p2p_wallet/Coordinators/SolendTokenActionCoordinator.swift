//
//  SolendTokenActionCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 29.09.2022.
//

import AnalyticsManager
import Combine
import Resolver
import UIKit

final class SolendTokenActionCoordinator: Coordinator<Void> {
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

    override func start() -> AnyPublisher<Void, Never> {
        let viewController: UIViewController
        let resultSubject = PassthroughSubject<Void, Never>()

        switch strategy {
        case let .tokenToDeposit(model):
            let view = TokenToDepositView(models: model)
            transition.containerHeight = view.viewHeight
            viewController = view.asViewController()
            view.close
                .sink(receiveValue: {
                    viewController.dismiss(animated: true)
                })
                .store(in: &subscriptions)
        case let .tokenToWithdraw(model):
            let view = TokenToWithdrawView(models: model)
            transition.containerHeight = view.viewHeight
            viewController = view.asViewController()
            view.close
                .sink(receiveValue: {
                    viewController.dismiss(animated: true)
                })
                .store(in: &subscriptions)
        }
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        controller.present(viewController, animated: true)

        transition.dimmClicked
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        viewController.onClose = {
            resultSubject.send()
        }
        return resultSubject.eraseToAnyPublisher()
    }
}

extension SolendTokenActionCoordinator {
    enum Strategy {
        case tokenToDeposit(model: [TokenToDepositView.Model])
        case tokenToWithdraw(model: [TokenToWithdrawView.Model])
    }
}
