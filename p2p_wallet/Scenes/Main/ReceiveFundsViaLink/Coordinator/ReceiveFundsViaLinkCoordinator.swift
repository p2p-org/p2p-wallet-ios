//
//  ReceiveFundsViaLinkCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 28.03.2023.
//

import AnalyticsManager
import Combine
import Foundation
import UIKit
import Resolver

final class ReceiveFundsViaLinkCoordinator: Coordinator<Void> {
    
    // Dependencies
    @Injected private var analyticsManager: AnalyticsManager
    
    // Subjects
    private let resultSubject = PassthroughSubject<Void, Never>()
    
    private let presentingViewController: UIViewController
    private let url: URL
    
    // MARK: - Init
    
    init(presentingViewController: UIViewController, url: URL) {
        self.presentingViewController = presentingViewController
        self.url = url
    }
    
    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = ReceiveFundsViaLinkViewModel(url: url)
        let view = ReceiveFundsViaLinkView(viewModel: viewModel)
        let viewController = view.asViewController()
        viewController.view.layer.cornerRadius = 16
        let transition = PanelTransition()
        transition.containerHeight = 446
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        presentingViewController.present(viewController, animated: true)
        
        viewModel.close
            .sink(receiveValue: { [weak self] in
                viewController.dismiss(animated: true)
                self?.resultSubject.send(())
            })
            .store(in: &subscriptions)
        viewModel.sizeChanged
            .sink(receiveValue: {
                transition.containerHeight = $0
                UIView.animate(withDuration: 0.25) {
                    transition.presentationController?.containerViewDidLayoutSubviews()
                }
            })
            .store(in: &subscriptions)
        
        var errorPresented = false
        viewModel.linkError
            .sink(receiveValue: { [weak self] model in
                guard let self = self else { return }
                
                errorPresented = true
                viewController.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    
                    let errorView = LinkErrorView(model: model) {
                        self.presentingViewController.dismiss(animated: true)
                    }.asViewController()
                    
                    errorView.deallocatedPublisher()
                        .sink(receiveValue: { [weak self] in
                            self?.resultSubject.send(())
                        })
                        .store(in: &self.subscriptions)
                    
                    errorView.modalPresentationStyle = .fullScreen
                    self.presentingViewController.present(errorView, animated: true)
                }
            })
            .store(in: &subscriptions)
        transition.dimmClicked
            .sink(receiveValue: {
                self?.analyticsManager.log(event: .claimClickHide)
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        transition.dismissed
            .sink(receiveValue: { [weak self] in
                if !errorPresented {
                    self?.resultSubject.send(())
                }
            })
            .store(in: &subscriptions)
        
        return resultSubject.prefix(1).eraseToAnyPublisher()
    }
}
