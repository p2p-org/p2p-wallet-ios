//
//  ProcessTransaction.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/03/2022.
//

import Foundation
import UIKit
import BEPureLayout

extension ProcessTransaction {
    final class ViewController: BaseVC {
        // MARK: - Properties
        private let viewModel: ProcessTransactionViewModelType
        private var detailViewController: TransactionDetail.ViewController!
        private var statusViewController: Status.ViewController!
        private var statusViewControllerShown = false
        
        // MARK: - Handlers
        var makeAnotherTransactionHandler: (() -> Void)?
        var backCompletion: (() -> Void)?
        var specificErrorHandler: ((Swift.Error) -> Void)?
        
        // MARK: - Initializer
        init(viewModel: ProcessTransactionViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            viewModel.sendAndObserveTransaction()
        }
        
        override func bind() {
            super.bind()
            
            viewModel.observingTransactionIndexDriver
                .filter {$0 != nil}
                .map {$0!}
                .distinctUntilChanged()
                .drive(onNext: {[weak self] index in
                    guard let self = self else {return}
                    self.detailViewController?.removeFromParent()
                    let vm = TransactionDetail.ViewModel(observingTransactionIndex: index)
                    self.detailViewController = TransactionDetail.ViewController(viewModel: vm)
                    self.detailViewController.backCompletion = self.makeAnotherTransactionHandler
                    self.add(child: self.detailViewController)
                })
                .disposed(by: disposeBag)
            
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if !statusViewControllerShown {
                statusViewController = .init(viewModel: viewModel)
                present(statusViewController, interactiveDismissalType: .none, completion: nil)
                statusViewControllerShown = true
            }
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .makeAnotherTransaction:
                statusViewController.dismiss(animated: true) {
                    self.makeAnotherTransactionHandler?()
                }
            case .specificErrorHandler(let error):
                statusViewController.dismiss(animated: true) {
                    self.specificErrorHandler?(error)
                }
            default:
                break
            }
        }
    }
}
