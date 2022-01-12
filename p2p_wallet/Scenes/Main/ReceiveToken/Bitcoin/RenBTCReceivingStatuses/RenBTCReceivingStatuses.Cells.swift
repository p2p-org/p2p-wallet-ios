//
//  RenBTCReceivingStatuses.Cells.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import BECollectionView

extension RenBTCReceivingStatuses {
    class TxCell: BECollectionCell, BECollectionViewCell {
        fileprivate var titleLabel: UILabel!
        fileprivate var descriptionLabel: UILabel!
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                UIStackView(axis: .horizontal, alignment: .top, distribution: .fill) {
                    UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                        UILabel(text: "<0.002 renBTC>", textSize: 15, weight: .medium, numberOfLines: 2)
                            .setupWithType(UILabel.self) { view in titleLabel = view }
                        UILabel(text: "<Minting>", textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
                            .setupWithType(UILabel.self) { view in descriptionLabel = view }
                    }
                    UIView.defaultNextArrow()
                }
                UIView.defaultSeparator().padding(.init(only: .top, inset: 14))
            }.padding(.init(x: 20, y: 12))
        }
        
        func setUp(with item: AnyHashable?) {
            guard let tx = item as? RenVM.LockAndMint.ProcessingTx else { return }
            titleLabel.text = "\(tx.value.toString(maximumFractionDigits: 9)) renBTC"
            descriptionLabel.text = tx.statusString
            
            descriptionLabel.textColor = .textSecondary
            if tx.mintedAt != nil {
                descriptionLabel.textColor = .attentionGreen
            }
        }
        
        func hideLoading() { contentView.hideLoader() }
        
        func showLoading() { contentView.showLoader() }
    }
    
    class RecordCell: BECollectionCell, BECollectionViewCell {
        fileprivate var titleLabel: UILabel!
        fileprivate var descriptionLabel: UILabel!
        fileprivate var resultLabel: UILabel!
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                UIStackView(axis: .horizontal, alignment: .top, distribution: .fill) {
                    UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                        UILabel(text: "<0.002 renBTC>", textSize: 15, weight: .medium, numberOfLines: 8)
                            .setupWithType(UILabel.self) { view in titleLabel = view }
                        UILabel(text: "<Minting>", textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
                            .setupWithType(UILabel.self) { view in descriptionLabel = view }
                    }
                    UIView.spacer
                    UILabel(textSize: 15, weight: .semibold)
                        .setupWithType(UILabel.self) { view in resultLabel = view }
                }
                UIView.defaultSeparator().padding(.init(only: .top, inset: 14))
            }.padding(.init(x: 20, y: 12))
        }
        
        func setUp(with item: AnyHashable?) {
            guard let tx = item as? Record else { return }
            titleLabel.text = tx.stringValue
            resultLabel.isHidden = true
            descriptionLabel.text = tx.time.string(withFormat: "HH:mm a")
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
        
        func hideLoading() { contentView.hideLoader() }
        
        func showLoading() { contentView.showLoader() }
    }
}
