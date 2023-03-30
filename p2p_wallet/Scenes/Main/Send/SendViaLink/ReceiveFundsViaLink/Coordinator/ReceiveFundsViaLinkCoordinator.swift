//
//  ReceiveFundsViaLinkCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 28.03.2023.
//

import Combine
import Foundation
import UIKit

final class ReceiveFundsViaLinkCoordinator: Coordinator<Void> {
    
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
        
        let viewController = UIBottomSheetHostingController(
            rootView: view,
            ignoresKeyboard: true
        )
        viewController.view.layer.cornerRadius = 20
        presentingViewController.present(viewController, interactiveDismissalType: .standard)
        
        viewModel.close
            .sink(receiveValue: { [weak self] in
                viewController.dismiss(animated: true)
                self?.resultSubject.send(())
            })
            .store(in: &subscriptions)
        viewModel.sizeChanged
            .sink(receiveValue: {
                DispatchQueue.main.async {
                    viewController.updatePresentationLayout(animated: true)
                }
            })
            .store(in: &subscriptions)
        viewModel.linkWasClaimed
            .sink(receiveValue: { [weak self] in
                viewController.dismiss(animated: true)
                
                let errorView = LinkWasClaimedView {
                    self?.presentingViewController.dismiss(animated: true)
                }.asViewController()
                
                errorView.modalPresentationStyle = .fullScreen
                self?.presentingViewController.present(errorView, animated: true)
            })
            .store(in: &subscriptions)
        
        return resultSubject.prefix(1).eraseToAnyPublisher()
    }
}
