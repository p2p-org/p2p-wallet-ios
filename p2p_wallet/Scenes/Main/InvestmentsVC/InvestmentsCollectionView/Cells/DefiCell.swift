//
//  DefiCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation
import BECollectionView

class DefiCell: BaseCollectionViewCell, LoadableView {
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill)
    
    lazy var imageView = UIImageView(width: 32, height: 32, backgroundColor: .gray, cornerRadius: 16)
    lazy var titleLabel = UILabel(text: "Token exchange", weight: .semibold, numberOfLines: 0)
    
    var loadingViews: [UIView] {
        [imageView, titleLabel]
    }
    
    override func commonInit() {
        super.commonInit()
        backgroundColor = .textWhite
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(all: 16))
        
        stackView.addArrangedSubviews([imageView, titleLabel])
    }
}

extension DefiCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let item = item as? Defi else {return}
        titleLabel.text = item.name
    }
}
