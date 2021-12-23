//
//  ProcessTransaction.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import Foundation
import UIKit

@objc protocol ProcessTransactionViewControllerDelegate: AnyObject {
    func processTransactionViewControllerDidComplete(_ vc: UIViewController)
}

extension ProcessTransaction {
    class ViewController: WLModalViewController {
        // MARK: - Properties
        private let viewModel: ProcessTransactionViewModelType
        weak var delegate: ProcessTransactionViewControllerDelegate?
        
        // MARK: - Initializer
        init(viewModel: ProcessTransactionViewModelType)
        {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func build() -> UIView {
            RootView(viewModel: viewModel)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.transactionDriver
                .drive(onNext: {[weak self] _ in
                    self?.updatePresentationLayout(animated: true)
                })
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
