//
//  TransactionDetailsCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 29.08.2022.
//

import Combine

final class TransactionDetailsCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let model: BuyTransactionDetailsView.Model

    private let transition = PanelTransition()

    init(
        navigationController: UINavigationController,
        model: BuyTransactionDetailsView.Model
    ) {
        self.navigationController = navigationController
        self.model = model
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = BuyTransactionDetailsView(model: model)
        transition.containerHeight = view.viewHeight
        let viewController = view.asViewController()
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        navigationController.present(viewController, animated: true)

        let resultSubject = PassthroughSubject<Void, Never>()
        view.dismiss
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
