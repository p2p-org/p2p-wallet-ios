//
//  ChooseWalletViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation
import UIKit

class ChooseWalletViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: ChooseWalletViewModel
    private lazy var rootView = ChooseWalletRootView(viewModel: viewModel)
    var completion: ((Wallet) -> Void)?
    
    // MARK: - Initializer
    init(viewModel: ChooseWalletViewModel)
    {
        self.viewModel = viewModel
        super.init()
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        containerView.addSubview(rootView)
        rootView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        viewModel.selectedWallet
            .subscribe(onNext: {[weak self] wallet in
                self?.completion?(wallet)
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
}

extension ChooseWalletViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        ExpandablePresentationController(presentedViewController: presented, presenting: presenting)
    }
}
