//
//  TransactionInfoViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import Foundation
import UIKit

class TransactionInfoViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: TransactionInfoViewModel
    lazy var rootView = TransactionInfoRootView(viewModel: viewModel)
    var viewTranslation = CGPoint(x: 0, y: 0)
    
    // MARK: - Initializer
    init(viewModel: TransactionInfoViewModel)
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
        viewModel.navigationSubject
            .subscribe(onNext: {[weak self] in self?.navigate(to: $0)})
            .disposed(by: disposeBag)
        
        viewModel.showDetailTransaction
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] _ in
                self?.forceResizeModal()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: TransactionInfoNavigatableScene) {
        switch scene {
        case .explorer:
            showWebsite(url: "https://explorer.solana.com/tx/\(viewModel.transaction.value.signature ?? "")")
        }
    }
}

extension TransactionInfoViewController: UIViewControllerTransitioningDelegate {
    private class PresentationController: FlexibleHeightPresentationController {
        override func calculateFittingHeightOfPresentedView(targetWidth: CGFloat) -> CGFloat {
            var height = super.calculateFittingHeightOfPresentedView(targetWidth: targetWidth)
            
            height += (presentedViewController as! TransactionInfoViewController)
                .rootView.intrinsicContentSize.height
            
            return height
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(position: .bottom, presentedViewController: presented, presenting: presenting)
    }
}
