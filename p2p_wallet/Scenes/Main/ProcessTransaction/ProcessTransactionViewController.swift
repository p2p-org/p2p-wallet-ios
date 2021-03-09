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
        
        }
    }
}

extension ProcessTransactionViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FlexibleHeightPresentationController(position: .bottom, presentedViewController: presented, presenting: presenting)
    }
}
