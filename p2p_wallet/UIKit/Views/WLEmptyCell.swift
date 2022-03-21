//
//  WLEmptyCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/04/2021.
//

import Foundation

class WLEmptyCell: BaseCollectionViewCell {
    lazy var imageView = UIImageView(width: 90, height: 90, image: .nothingFound)
    lazy var titleLabel = UILabel(text: L10n.nothingFound, textSize: 17, weight: .medium, textAlignment: .center)
    lazy var subtitleLabel = UILabel(
        text: L10n.theListIsEmpty,
        weight: .medium,
        textColor: .textSecondary,
        numberOfLines: 0,
        textAlignment: .center
    )

    override func commonInit() {
        super.commonInit()
        stackView.spacing = 16
        stackView.alignment = .center

        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            BEStackViewSpacing(6),
            subtitleLabel,
        ])
    }
}
