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
            showWebsite(url: "https://explorer.solana.com/tx/\(viewModel.transaction.value.parsed?.signature ?? "")")
        }
    }
}

extension TransactionInfoViewController: UIViewControllerTransitioningDelegate {
    private class PresentationController: FlexibleHeightPresentationController {
        var originFrame: CGRect?
        var state: UIPanGestureRecognizer.State?
        
        override func calculateFittingHeightOfPresentedView(targetWidth: CGFloat) -> CGFloat {
            
            let rootView = (presentedViewController as! TransactionInfoViewController)
                .rootView
            
            var height = rootView.headerView.fittingHeight(targetWidth: targetWidth) + 14
            
            height += rootView.scrollView.contentSize.height
            height += rootView.scrollView.contentInset.top
            height += rootView.scrollView.contentInset.bottom
            
            return height
        }
        
        override var frameOfPresentedViewInContainerView: CGRect {
            if state == .ended, let frame = originFrame {
                originFrame = nil
                return frame
            }
            return super.frameOfPresentedViewInContainerView
        }
        
        override func presentedViewDidSwipe(gestureRecognizer: UIPanGestureRecognizer) {
            guard let view = gestureRecognizer.view else {return}
            state = gestureRecognizer.state
            
            if state == .began {
                originFrame = view.frame
            }
            
            super.presentedViewDidSwipe(gestureRecognizer: gestureRecognizer)
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(position: .bottom, presentedViewController: presented, presenting: presenting)
    }
}
