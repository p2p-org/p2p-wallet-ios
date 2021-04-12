//
//  WLEmptyCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/04/2021.
//

import Foundation

class WLEmptyCell: BaseCollectionViewCell {
    private lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .center, distribution: .fill)
    lazy var imageView = UIImageView(width: 90, height: 90, image: .nothingFound)
    lazy var titleLabel = UILabel(text: L10n.nothingFound, textSize: 17, weight: .medium, textAlignment: .center)
    lazy var subtitleLabel = UILabel(text: L10n.changeYourSearchPhrase, weight: .medium, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
    
    override func commonInit() {
        super.commonInit()
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(top: 50, left: 20, bottom: 50, right: 20))
        
        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            BEStackViewSpacing(6),
            subtitleLabel
        ])
    }
}
