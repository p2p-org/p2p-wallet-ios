//
//  ProcessTransactionViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2021.
//

import Foundation
import UIKit

class ProcessTransactionViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: ProcessTransactionViewModel
    var viewInExplorerCompletion: (() -> Void)?
    
    // MARK: - Initializer
    init(viewModel: ProcessTransactionViewModel)
    {
        self.viewModel = viewModel
        super.init()
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        let rootView = ProcessTransactionRootView(viewModel: viewModel)
        rootView.transactionDidChange = { [unowned self] in
            self.forceResizeModal()
        }
        containerView.addSubview(rootView)
        rootView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: ProcessTransactionNavigatableScene) {
        switch scene {
        case .viewInExplorer(let signature):
            let pc = self.presentingViewController
            self.dismiss(animated: true) {
                if let rootVC = pc?.presentingViewController {
                    pc?.dismiss(animated: true, completion: {
                        rootVC.showWebsite(url: "https://explorer.solana.com/tx/" + signature)
                    })
                } else {
                    pc?.showWebsite(url: "https://explorer.solana.com/tx/" + signature)
                }
            }
        case .done:
            self.dismiss(animated: true) {
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension ProcessTransactionViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = FlexibleHeightPresentationController(position: .bottom, presentedViewController: presented, presenting: presenting)
        // disable dismissing on dimmingView
        pc.dimmingView.gestureRecognizers?.forEach {pc.dimmingView.removeGestureRecognizer($0)}
        return pc
    }
}
