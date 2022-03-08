//
//  TransactionDetail.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Foundation
import UIKit
import BEPureLayout

extension TransactionDetail {
    class ViewController: BEScene {
        // MARK: - Dependencies
        private let viewModel: TransactionDetailViewModelType
        
        // MARK: - Properties
        
        // MARK: - Initializer
        init(viewModel: TransactionDetailViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func build() -> UIView {
            BEVStack {
                // Navigation Bar
                NavigationBar()
                    .onBack { [unowned self] in self.back() }
                    .driven(with: viewModel.parsedTransactionDriver)
                
                // Scrollable View
                ContentHuggingScrollView(
                    axis: .vertical,
                    contentInsets: .init(x: 18, y: 12),
                    spacing: 8
                ) {
                    // Status View
                    StatusView()
                        .driven(with: viewModel.parsedTransactionDriver)
                    
                    // Panel
                    UIView.floatingPanel(contentInset: .init(x: 8, y: 16)) {
                        WalletsView()
                            .driven(with: viewModel.parsedTransactionDriver)
                    }
                    
                    // Tap and hold to copy
                    TapAndHoldView()
                        .setup { view in
                            view.closeHandler = { [unowned self] in
                                
                            }
                        }
                        
                    
                }
                
                UIView()
            }
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .explorer(let url):
//                let vc = Detail.ViewController()
//                present(vc, completion: nil)
                break
            }
        }
    }
}
