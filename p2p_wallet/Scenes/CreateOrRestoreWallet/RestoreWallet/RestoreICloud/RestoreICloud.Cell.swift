//
//  RestoreICloud.Cell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import Foundation
import BECollectionView

extension RestoreICloud {
    class Cell: BaseCollectionViewCell, BECollectionViewCell {
        override var padding: UIEdgeInsets {.init(x: 20, y: 12)}
        
        lazy var topLabel = UILabel(text: "<top>", textSize: 13, weight: .medium, textColor: .textSecondary)
        lazy var bottomLabel = UILabel(text: "<bottom>", textSize: 15, weight: .medium)
        
        override func commonInit() {
            super.commonInit()
            stackView.axis = .horizontal
            stackView.alignment = .center
            
            stackView.addArrangedSubviews {
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    topLabel
                    bottomLabel
                }
                UIView.defaultNextArrow()
            }
            
            stackView.autoSetDimension(.height, toSize: 48)
            
            let separator = UIView.defaultSeparator()
            contentView.addSubview(separator)
            separator.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0), excludingEdge: .top)
        }
        
        func setUp(with item: AnyHashable?) {
            guard let account = item as? ParsedAccount else {return}
            let pubkey = account.parsedAccount.publicKey.base58EncodedString.truncatingMiddle(numOfSymbolsRevealed: 12, numOfSymbolsRevealedInSuffix: 4)
            
            topLabel.isHidden = false
            
            if let name = account.account.name {
                topLabel.text = pubkey
                bottomLabel.text = name.withNameServiceSuffix()
            } else {
                topLabel.isHidden = true
                bottomLabel.text = pubkey
            }
        }
    }
}
