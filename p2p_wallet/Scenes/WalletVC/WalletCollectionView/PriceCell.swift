//
//  PriceCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class PriceCell: BaseCollectionViewCell {
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .top, distribution: .fill)
    lazy var coinNameLabel = UILabel(text: "Coin name", textSize: 15, weight: .semibold, numberOfLines: 0)
    override func commonInit() {
        super.commonInit()
        contentView.backgroundColor = .background
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        
        stackView.addArrangedSubview(coinNameLabel)
    }
}
