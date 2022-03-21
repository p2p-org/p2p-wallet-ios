//
//  DefiCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import BECollectionView
import Foundation

class DefiCell: BaseCollectionViewCell {
    override var padding: UIEdgeInsets { .init(all: 16) }
    lazy var imageView = UIImageView(width: 32, height: 32, backgroundColor: .gray, cornerRadius: 16)
    lazy var titleLabel = UILabel(text: "Token exchange", weight: .semibold, numberOfLines: 0)

    override func commonInit() {
        super.commonInit()
        backgroundColor = .textWhite

        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center

        stackView.addArrangedSubviews {
            imageView
            titleLabel
        }
    }
}

extension DefiCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let item = item as? Defi else { return }
        titleLabel.text = item.name
    }
}
