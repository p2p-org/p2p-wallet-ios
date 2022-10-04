//
//  SolendTransactionDetailsCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 29.09.2022.
//

import Combine
import Resolver
import SwiftUI
import UIKit

final class SolendTransactionDetailsCoordinator: Coordinator<Void> {
    typealias Strategy = SolendTransactionDetailsView.Strategy
    typealias Model = SolendTransactionDetailsView.State

    private let controller: UIViewController
    private let strategy: Strategy
    private let model: Binding<Model>

    private let transition = PanelTransition()

    init(
        controller: UIViewController,
        strategy: Strategy,
        model: Binding<Model>
    ) {
        self.controller = controller
        self.strategy = strategy
        self.model = model
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SolendTransactionDetailsView(strategy: strategy, model: model)
        transition.containerHeight = view.viewHeight
        let viewController = view.asViewController()
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        controller.present(viewController, animated: true)

        view.close
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        let resultSubject = PassthroughSubject<Void, Never>()
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
