//
//  PT.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import UIKit
import BEPureLayout

extension PT {
    class ViewController: WLModalViewController {
        // MARK: - Dependencies
        private let viewModel: PTViewModelType
        
        // MARK: - Properties
        
        init(viewModel: PTViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func build() -> UIView {
            BEContainer {
                BEVStack(spacing: 4) {
                    // The transaction is being processed
                    UILabel(
                        text: L10n.theTransactionIsBeingProcessed,
                        textSize: 20,
                        weight: .bold,
                        numberOfLines: 0,
                        textAlignment: .center
                    )
                        .padding(.init(x: 18, y: 0))
                    
                    // Detail
                    UILabel(
                        text: "0.00227631 renBTC → DkmT...JnBw",
                        textSize: 15,
                        textColor: .textSecondary,
                        numberOfLines: 0,
                        textAlignment: .center
                    )
                        .padding(.init(all: 18, excludingEdge: .top))
                    
                    // Loader
                    BEZStack {
                        // Process indicator
                        BEZStackPosition {
                            UIProgressView(height: 2)
                                .setup {view in
                                    view.progressTintColor = .h5887ff
                                    view.progress = 0.4
                                }
                                .centered(.vertical)
                        }
                        
                        // Icon
                        BEZStackPosition {
                            UIImageView(width: 44, height: 44, image: .squircleTransactionProcessing)
                                .centered(.horizontal)
                        }
                    }
                        .padding(.init(only: .bottom, inset: 18))
                    
                    // Transaction ID
                    BEHStack(spacing: 4, alignment: .top, distribution: .fill) {
                        UILabel(text: L10n.transactionID, textSize: 15, textColor: .textSecondary)
                        
                        BEVStack(spacing: 4, alignment: .fill, distribution: .fill) {
                            BEHStack(spacing: 4, alignment: .center, distribution: .fill) {
                                UILabel(text: "4gj7UK2mG...NjweNS39N", textSize: 15, textAlignment: .right)
                                UIImageView(width: 16, height: 16, image: .transactionShowInExplorer, tintColor: .textSecondary)
                            }
                            UILabel(text: L10n.tapToViewInExplorer, textSize: 15, textColor: .textSecondary, numberOfLines: 0, textAlignment: .right)
                        }
                            .onTap { [weak self] in
                                // TODO: - Tap to view in explorer
                                
                            }
                    }
                        .padding(.init(top: 0, left: 18, bottom: 36, right: 18))
                        .setup { view in
                            view.isHidden = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak view, weak self] in
                                view?.isHidden = false
                                self?.updatePresentationLayout()
                            }
                        }
                    
                    // Buttons
                    BEVStack(spacing: 10) {
                        WLStepButton.main(image: .info, text: L10n.showTransactionDetails)
                            .onTap { [weak self] in
                                self?.viewModel.navigate(to: .detail)
                            }
                        WLStepButton.sub(text: L10n.makeAnotherTransaction)
                            .onTap { [weak self] in
                                // TODO: - Make another transaction
                                
                            }
                    }
                        .padding(.init(x: 18, y: 0))
                }
                    .padding(.init(x: 0, y: 18))
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
            case .detail:
                let vc = DetailViewController()
                present(vc, animated: true, completion: nil)
            case .explorer(transactionID: let transactionID):
                break
            }
        }
    }
}
