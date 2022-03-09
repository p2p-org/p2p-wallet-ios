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
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
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
                BEScrollView(
                    axis: .vertical,
                    contentInsets: .init(x: 18, y: 12),
                    spacing: 18
                ) {
                    // Status View
                    StatusView()
                        .driven(with: viewModel.parsedTransactionDriver)
                    
                    // Panel
                    UIView.floatingPanel(contentInset: .init(x: 8, y: 16)) {
                        SummaryView()
                            .driven(with: viewModel.parsedTransactionDriver)
                    }
                    
                    // Tap and hold to copy
                    UIView.greyBannerView {
                        TapAndHoldView()
                            .setup { view in
                                view.closeHandler = { [unowned view] in
                                    UIView.animate(withDuration: 0.3) {
                                        view.superview?.superview?.isHidden = true
                                    }
                                }
                            }
                    }
                        
                    // Transaction id
                    BEHStack(spacing: 4, alignment: .top) {
                        titleLabel(text: L10n.transactionID)
                        
                        BEVStack(spacing: 4) {
                            // Transaction id
                            BEHStack(spacing: 4, alignment: .center) {
                                addressLabel()
                                UIImageView(width: 16, height: 16, image: .transactionShowInExplorer, tintColor: .textSecondary)
                            }
                            
                            UILabel(text: L10n.tapToViewInExplorer, textSize: 15, textColor: .textSecondary, textAlignment: .right)
                        }
                            .onTap { [unowned self] in
                                // Show in explorer
                            }
                    }
                    
                    // Separator
                    UIView.defaultSeparator()
                    
                    // Sender
                    BEHStack(spacing: 4, alignment: .top) {
                        titleLabel(text: L10n.senderSAddress)
                        
                        BEVStack(spacing: 8) {
                            addressLabel()
                            nameLabel()
                        }
                    }
                    
                    // Separator
                    UIView.defaultSeparator()
                    
                    // Recipient
                    BEHStack(spacing: 4, alignment: .top) {
                        titleLabel(text: L10n.recipientSAddress)
                        
                        BEVStack(spacing: 8) {
                            addressLabel()
                            nameLabel()
                        }
                    }
                    
                    // Separator
                    UIView.defaultSeparator()
                    
                    // Amounts
                    BEVStack(spacing: 8) {
                        BEHStack(spacing: 4) {
                            titleLabel(text: L10n.received)
                            
                            UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
                        }
                        
                        BEHStack(spacing: 4) {
                            titleLabel(text: L10n.transferFee)
                            
                            UILabel(text: "Free (Paid by P2P.org)", textSize: 15, textAlignment: .right)
                        }
                        
                        BEHStack(spacing: 4) {
                            titleLabel(text: L10n.total)
                            
                            UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
                        }
                    }
                    
                    // Separator
                    UIView.defaultSeparator()
                    
                    // Block number
                    BEHStack(spacing: 4) {
                        titleLabel(text: L10n.blockNumber)
                        
                        UILabel(text: "#5387498763", textSize: 15, textAlignment: .right)
                    }
                }
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
        
        private func titleLabel(text: String) -> UILabel {
            UILabel(text: text, textSize: 15, textColor: .textSecondary, numberOfLines: 2)
        }
        
        private func addressLabel() -> UILabel {
            UILabel(text: "FfRBgsYFtBW7Vo5hRetqEbdxrwU8KNRn1ma6sBTBeJEr", textSize: 15, numberOfLines: 2, textAlignment: .right)
        }
        
        private func nameLabel() -> UILabel {
            UILabel(text: "name.p2p.sol", textSize: 15, textColor: .textSecondary, textAlignment: .right)
        }
    }
}
