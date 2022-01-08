//
//  ProcessTransaction.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import Foundation
import UIKit
import RxSwift

@objc protocol ProcessTransactionViewControllerDelegate: AnyObject {
    func processTransactionViewControllerDidComplete(_ vc: UIViewController)
}

extension ProcessTransaction {
    class ViewController: WLIndicatorModalVC {
        
        // MARK: - Dependencies
        private let viewModel: ProcessTransactionViewModelType
        
        // MARK: - Properties
        weak var delegate: ProcessTransactionViewControllerDelegate?
        
        // MARK: - Initializer
        init(viewModel: ProcessTransactionViewModelType) {
            self.viewModel = viewModel
            super.init()
            modalPresentationStyle = .custom
            transitioningDelegate = self
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            let rootView = RootView(viewModel: viewModel)
            rootView.transactionStatusDidChange = { [weak self] in
                self?.forceResizeModal()
            }
            containerView.addSubview(rootView)
            rootView.autoPinEdgesToSuperviewEdges()
            
            if let gesture = swipeGesture {
                view.removeGestureRecognizer(gesture)
            }
        }
        
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .showExplorer(let transactionID):
                self.showWebsite(url: "https://explorer.solana.com/tx/" + transactionID)
            case .done:
                if let delegate = delegate {
                    delegate.processTransactionViewControllerDidComplete(self)
                } else {
                    let pc = presentingViewController
                    self.dismiss(animated: true) {
                        pc?.dismiss(animated: true, completion: nil)
                    }
                }
            case .cancel:
                self.dismiss(animated: true, completion: nil)
            case .none:
                break
            }
        }
    }
}

extension ProcessTransaction.ViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = FlexibleHeightPresentationController(position: .bottom, presentedViewController: presented, presenting: presenting)
        // disable dismissing on dimmingView
        pc.dimmingView.gestureRecognizers?.forEach {pc.dimmingView.removeGestureRecognizer($0)}
        return pc
    }
}
