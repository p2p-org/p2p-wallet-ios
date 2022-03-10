//
//  TransactionDetail.FeesSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2022.
//

import Foundation
import UIKit
import RxSwift
import BEPureLayout

extension TransactionDetail {
    final class FeesSection: UIStackView {
        private let disposeBag = DisposeBag()
        private let viewModel: TransactionDetailViewModelType
        
        init(viewModel: TransactionDetailViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill)
            addArrangedSubviews {
                // Separator
                UIView.defaultSeparator()
                
                // Amounts
                BEVStack(spacing: 8) {
                    
//                    // Received: for TransferTransaction
//                    BEHStack(spacing: 4) {
//                        titleLabel(text: L10n.received)
//
//                        UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
//                    }
                    
                    BEHStack(spacing: 4) {
                        titleLabel(text: L10n.transferFee)
                        
                        UILabel(text: "Free (Paid by P2P.org)", textSize: 15, textAlignment: .right)
                            .setup { label in
                                viewModel.parsedTransactionDriver
                                    .map {$0?.fee ?? 0}
                                    .map {"\($0) lamports"}
                                    .drive(label.rx.text)
                                    .disposed(by: disposeBag)
                            }
                    }
                    
//                    BEHStack(spacing: 4) {
//                        titleLabel(text: L10n.total)
//
//                        UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
//                    }
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func titleLabel(text: String) -> UILabel {
            UILabel(text: text, textSize: 15, textColor: .textSecondary, numberOfLines: 2)
        }
    }
}
