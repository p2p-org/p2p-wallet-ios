//
//  DerivablePathCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import BECollectionView
import Foundation

extension DerivablePaths {
    class Cell: BaseCollectionViewCell, BECollectionViewCell {
        override var padding: UIEdgeInsets { .init(all: 22) }

        private lazy var radioButton = WLRadioButton()
        private lazy var titleLabel = UILabel(textSize: 17, numberOfLines: 0)

        override func commonInit() {
            super.commonInit()
            stackView.axis = .horizontal
            stackView.spacing = 20
            stackView.alignment = .center

            stackView.addArrangedSubviews {
                radioButton
                titleLabel
            }
        }

        func setUp(with item: AnyHashable?) {
            guard let path = item as? SelectableDerivablePath else { return }
            radioButton.isSelected = path.isSelected
            titleLabel.text = path.path.title
        }
    }
}
