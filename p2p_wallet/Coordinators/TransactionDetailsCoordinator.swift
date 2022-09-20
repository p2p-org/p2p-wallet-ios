//
//  TransactionDetailsCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 29.08.2022.
//

import AnalyticsManager
import Combine
import Resolver
import UIKit

final class TransactionDetailsCoordinator: Coordinator<Void> {
    @Injected private var analyticsManager: AnalyticsManager
    private let controller: UIViewController
    private let model: BuyTransactionDetailsView.Model

    private let transition = PanelTransition()

    init(
        controller: UIViewController,
        model: BuyTransactionDetailsView.Model
    ) {
        self.controller = controller
        self.model = model
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = BuyTransactionDetailsView(model: model)
        transition.containerHeight = view.viewHeight
        let viewController = view.asViewController()
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        controller.present(viewController, animated: true)
        analyticsManager.log(event: AmplitudeEvent.buyTotalShowed)

        transition.dimmClicked
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)

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
