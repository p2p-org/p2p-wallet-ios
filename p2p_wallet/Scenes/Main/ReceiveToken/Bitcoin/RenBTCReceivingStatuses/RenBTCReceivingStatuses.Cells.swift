//
//  RenBTCReceivingStatuses.Cells.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import BECollectionView

extension RenBTCReceivingStatuses {
    class TxCell: BaseCollectionViewCell, BECollectionViewCell {
        override var padding: UIEdgeInsets {.init(x: 20, y: 12)}
        
        // MARK: - Subviews
        fileprivate lazy var titleLabel = UILabel(text: "<0.002 renBTC>", textSize: 15, weight: .medium)
        fileprivate lazy var descriptionLabel = UILabel(text: "<Minting>", textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            stackView.spacing = 8
            stackView.axis = .horizontal
            stackView.alignment = .center
            
            stackView.addArrangedSubviews {
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    titleLabel
                    descriptionLabel
                }
                UIView.defaultNextArrow()
            }
        }
        
        func setUp(with item: AnyHashable?) {
            guard let tx = item as? RenVM.LockAndMint.ProcessingTx else {return}
            titleLabel.text = "\(tx.value.toString(maximumFractionDigits: 9)) renBTC"
            descriptionLabel.text = tx.statusString
            
            descriptionLabel.textColor = .textSecondary
            if tx.mintedAt != nil {
                descriptionLabel.textColor = .attentionGreen
            }
        }
    }
    
    class RecordCell: TxCell {
        private lazy var resultLabel = UILabel(textSize: 15, weight: .semibold)
        override func commonInit() {
            super.commonInit()
            stackView.arrangedSubviews.last?.removeFromSuperview()
            stackView.addArrangedSubview(resultLabel.withContentHuggingPriority(.required, for: .horizontal))
        }
        
        override func setUp(with item: AnyHashable?) {
            guard let tx = item as? Record else {return}
            titleLabel.text = tx.stringValue
            resultLabel.isHidden = true
            descriptionLabel.text = tx.time.string(withFormat: "MMMM dd, YYYY HH:mm a")
            switch tx.status {
            case .waitingForConfirmation:
                resultLabel.isHidden = false
                let vout = tx.vout ?? 0
                let max = 3
                resultLabel.text = "\(vout)/\(max)"
                if vout == 0 {
                    resultLabel.textColor = .alert
                } else if vout == max {
                    resultLabel.textColor = .textGreen
                } else {
                    resultLabel.textColor = .textBlack
                }
            case .minted:
                resultLabel.isHidden = false
                resultLabel.text = "+ \((tx.amount ?? 0).convertToBalance(decimals: 8).toString(maximumFractionDigits: 9)) renBTC"
                resultLabel.textColor = .textGreen
            default:
                break
            }
        }
    }
}
