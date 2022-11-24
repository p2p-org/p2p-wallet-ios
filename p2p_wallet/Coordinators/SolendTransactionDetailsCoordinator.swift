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
    typealias Strategy = SolendTransactionDetailsViewModel.Strategy
    typealias Model = SolendTransactionDetailsView.Model

    private let controller: UIViewController
    private let strategy: Strategy
    private let model: AnyPublisher<Model?, Never>

    private let transition = PanelTransition()

    init(
        controller: UIViewController,
        strategy: Strategy,
        model: AnyPublisher<Model?, Never>
    ) {
        self.controller = controller
        self.strategy = strategy
        self.model = model
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = SolendTransactionDetailsViewModel(strategy: strategy, model: nil)
        let view = SolendTransactionDetailsView(viewModel: viewModel)
        transition.containerHeight = view.viewHeight
        let viewController = view.asViewController()
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        controller.present(viewController, animated: true)

        model.assign(to: \.model, on: viewModel).store(in: &subscriptions)

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
