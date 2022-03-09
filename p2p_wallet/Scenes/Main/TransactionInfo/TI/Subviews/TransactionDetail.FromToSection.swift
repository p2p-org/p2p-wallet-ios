//
//  TransactionDetail.FromToSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2022.
//

import Foundation
import UIKit

extension TransactionDetail {
    final class FromToSection: UIStackView {
        private let fromTitleLabel = titleLabel()
        private let fromAddressLabel = addressLabel()
        private let fromNameLabel = nameLabel()
        
        private let toTitleLabel = titleLabel()
        private let toAddressLabel = addressLabel()
        private let toNameLabel = nameLabel()
        
        init() {
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill)
            addArrangedSubviews {
                // Separator
                UIView.defaultSeparator()
                
                // Sender
                BEHStack(spacing: 4, alignment: .top) {
                    fromTitleLabel
                    
                    BEVStack(spacing: 8) {
                        fromAddressLabel
                        fromNameLabel
                    }
                }
                
                // Separator
                UIView.defaultSeparator()
                
                // Recipient
                BEHStack(spacing: 4, alignment: .top) {
                    toTitleLabel
                    
                    BEVStack(spacing: 8) {
                        toAddressLabel
                        toNameLabel
                    }
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

private func titleLabel() -> UILabel {
    UILabel(text: "Sender’s address", textSize: 15, textColor: .textSecondary, numberOfLines: 2)
}

private func addressLabel() -> UILabel {
    UILabel(text: "FfRBgsYFtBW7Vo5hRetqEbdxrwU8KNRn1ma6sBTBeJEr", textSize: 15, numberOfLines: 2, textAlignment: .right)
}

private func nameLabel() -> UILabel {
    UILabel(text: "name.p2p.sol", textSize: 15, textColor: .textSecondary, textAlignment: .right)
}
